models    = require './models'
config    = require './config'
stripe    = require('stripe')(config.stripe)
Users     = models.User
WCClass     = models.WCClass
mailer    = require './mailer'


module.exports = (app) ->
  app.get "/robots.txt", (req, res) ->
    res.type('text/plain')
    res.send "User-agent: *\n"+
        "Disallow: /images/\n"+
        "Disallow: /css/\n"+
        "Disallow: /js/\n"

  app.get "/", (req, res) ->
    res.render "index.jade"

  app.get "/work", (req, res) ->
    res.render "work.jade",
      title: "Our Work | Wiley Cousins"

  app.get "/classes", (req, res) ->
    res.render "classes.jade",
      components_kit: 20
      everything_kit: 60
      stripe_js: config.stripe_js
      title: "Get Clever | Wiley Cousins"

  app.post "/classes", (req, res) ->
    name = req.body.name
    email = req.body.email
    phone = req.body.phone
    address = req.body.address
    city = req.body.city
    state = req.body.state
    zip = req.body.zip
    classes = req.body.classes
    class_name = req.body.class_name
    amount = req.body.amount
    kit = req.body.kit
    kit = parseInt kit
    amount = parseFloat amount
    classes = parseInt classes
    is_small_business = req.body.is_small_business

    # server side validate that the amount is right
    amt = 0
    if classes is 1
      amt = 10
    else if classes is 4
      amt = 40
    else if classes is 12
      amt = 100
    if class_name == 'intro-circuits'
      amt *= 2
      amt += parseInt kit

    amt = (amt + 0.3)/(1-0.029)
    amt = Math.round(amt * 100) / 100
    if amt.toString().split('.')[1].length < 2
      amt = parseFloat "#{amt}0"

    if amount != amt || amount < 5
      return res.render "error.jade", is_html: true, error:  "<h3 class='white'>your total is'nt adding up right. Try submitting again?</h3>"
    stripeToken = req.body.stripeToken


    charge =
      description: "#{name} <#{email}> (#{phone}) @ #{address}, #{city}, #{state}, #{zip}"
      amount: amount*100
      currency: 'USD'
      card: stripeToken

    Users.findOne(
      email: email
    ).exec (err, user) ->
      if err
        console.log err
        mailer.sendEmailError err, req
        return res.render "error.jade", is_html: true, error:  "<h3 class='white'>error finding user in db, sorry</h3>"
      if !user
        user = new Users
          name: name
          email: email
          phone: phone
          address: address
          city: city
          state: state
          zip: zip
        user.save()
      user.is_small_business = is_small_business
      stripe.charges.create charge, (err, charge) ->
        if err
          console.log err
          mailer.sendEmailError err, req
          return res.render "error.jade", is_html: true, error:  "<h3>error creating your purchase record, sorry. try again.</h3><p>if you have problems email <a href='mailto:dev@wileycousins.com'>dev@wileycousins.com</a> and complain</p>"
        else
          kit = kit || 0
          addClass = (next) ->
            wcclass = new WCClass(buyer: user, kit: kit, name: class_name, has_paid: true)
            wcclass.save (err, wcclass) ->
              next err, wcclass
          wcclasses = []
          count = i = parseInt classes
          while --i >= 0
            addClass (err, wcclass) ->
              if err
                console.log err
                mailer.sendEmailError err, req
                return res.render "error.jade", is_html: true, error:  "<h3 class='white'>your card has been charged, but we had an error saving purchase record in db, sorry. email dev@wileycousins.com and complain</h3>"
              wcclasses.push wcclass
              if --count <= 0
                for c in wcclasses
                  user.purchased_wcclasses.addToSet c
                user.save (err, user) ->
                  mailer.newPurchase user, wcclass
                return res.redirect '/purchase'

  app.get "/my-classes", (req, res) ->
    if !req.query.email
      return res.render "getEmail.jade"
    Users.find( email: req.query.email ).populate('purchased_wcclasses').exec (err, users) ->
      if err
        return res.render "error.jade", error: err
      if users.length == 0
        return res.render "getEmail.jade", error:"Didn't find an account for <span class='blue'>#{req.query.email}</span><br>you sure you signed up?<br>If you are having problems email <a href='mailto:dev@wileycousins.com'> wiley cousins</a>"
      user = users[0]
      return res.render "my_classes.jade",
        user:user
        wcclasses: user.purchased_wcclasses

  app.post "/my-classes", (req, res) ->
    return res.redirect("/my-classes?email=#{req.body.email}")
  
  isAdmin = (req, res, next) -> 
    if process.env.NODE_ENV.match('production') && (!req.session.auth?.match('so-good') && !req.body.password?.match(process.env.ADMIN_PASSWORD))
      return res.render 'login'
    else
      req.session['auth'] = 'so-good'
      next()

  app.all "/login", isAdmin, (req, res) ->
    return res.redirect('/orders')

  app.all "/email-error", isAdmin, (req, res) ->
    return res.render 'emailTemplates/error.jade', error: null, req: req

  app.get "/orders", isAdmin, (req, res) ->
    Users.find().populate('purchased_wcclasses').exec (err, users) ->
      if err
        console.log err
        return res.send err
      users.sort (a,b) ->
        a.purchased_wcclasses[0]?.purchase_date - b.purchased_wcclasses[0]?.purchase_date
      paid_users = []
      signed_up = []
      for user in users
        has_paid = false
        user['prog_classes'] = []
        user['circ_classes'] = []
        user['used_prog_classes'] = []
        user['used_circ_classes'] = []
        for c in user.purchased_wcclasses
          if c.has_paid
            has_paid = true
            if c.name == 'intro-circuits'
              if c.been_used
                user['used_circ_classes'].push c
              else
                if c.been_used
                  user['used_circ_classes'].push c
                else
                  user['circ_classes'].push c
            else
              user['prog_classes'].push c
        if has_paid
          paid_users.push user
        else
          signed_up.push user
      return res.render "orders.jade", paid_users: paid_users, signed_up:signed_up

  app.get "/purchase", (req, res) ->
    return res.render 'purchase'

  app.get "/confirmation", isAdmin, (req, res) ->
    Users.findOne( email: 'hcwiley@gmail.com' )
      .populate('purchased_wcclasses')
      .exec (err, user) ->
        if err
          console.log err
        return res.render 'emailTemplates/confirmation',
          user: user
          wcclass: user.purchased_wcclasses[0]
          url: config.url

  app.get "/confirmation/:user", isAdmin, (req, res) ->
    res.redirect '/orders'

  app.post "/confirmation/:user", isAdmin, (req, res) ->
    Users.findById(req.params.user).exec (err, user) ->
      if err
        console.log err
      console.log req.body.clock
      WCClass.find({purchase_date:{$lte:req.body.clock}}).exec (err, wcclasses) ->
        if err
          console.log err
        num = wcclasses.length
        if num < 10
          num = "0#{num.toString()}"
        mailer.confirmation user, num
        return res.render 'emailTemplates/confirmation', user: user, num:num, url: config.url

  app.post "/classes/:id", isAdmin, (req, res) ->
    WCClass.findById(req.params.id).exec (err, wcclass) ->
      if err
        console.log err
        return res.send err, 500
      if !wcclass
        console.log "no class"
        return res.send "no class", 500
      if req.body.action == 'delete'
        Users.findById(wcclass.buyer).exec (err, user) ->
          if err
            console.log err
            return res.send err, 500
          if !user
            console.log 'no user'
            return res.send 'no user', 500
          user.purchased_wcclasses.remove wcclass
          wcclass.remove()
          user.save (err, user) ->
            return res.send 'gone'
      else if req.body.action == 'used'
        wcclass.been_used = true
        wcclass.used_date = (new Date())
        wcclass.save (err, wcclass) ->
          return res.json wcclass


  app.post "/update/:user", isAdmin, (req, res) ->
    console.log "updating"
    Users.findById(req.params.user).populate("purchased_wcclasses").exec (err, user) ->
      if err || !user
        console.log err
        return res.send err
      user.name = req.body.name
      user.phone = req.body.phone
      user.email = req.body.email
      user.address = req.body.address
      user.city = req.body.city
      user.state = req.body.state
      console.log "updated the fields"
      console.log user
      user.save()
    res.redirect '/orders'

  app.delete "/update/:user", isAdmin, (req, res) ->
    Users.findById(req.params.user).exec (err, user) ->
      for c in user.purchased_wcclasses
        WCClass.findById(c).exec (err, _class) ->
          _class.remove()
      user.remove()
      return res.redirect '/orders'
