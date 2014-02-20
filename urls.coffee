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
      everything_kit: 40
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
    amount = parseFloat amount
    classes = parseInt classes

    console.log req.body

    if amount < 5
      return res.send "not a good amount"
    stripeToken = req.body.stripeToken

    console.log "amount #{amount}"

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
        return res.send "error finding user in db, sorry"
      if !user
        console.log "new user"
        user = new Users
          name: name
          email: email
          phone: phone
          address: address
          city: city
          state: state
          zip: zip
        user.save()
      stripe.charges.create charge, (err, charge) ->
        if err
          console.log err
          return res.send "<h3>error creating your purchase record, sorry. try again.</h3><p>if you have problems email <a href='mailto:dev@wileycousins.com'>dev@wileycousins.com</a> and complain</p>"
        else
          kit = kit || 0
          i = parseInt classes
          while i-- > 0
            console.log 'saving new class'
            wcclass = new WCClass(buyer: user, kit: kit, name: class_name, has_paid: true)
            console.log "new class: #{wcclass}"
            wcclass.save (err, wcclass) ->
              console.log 'saved class'
              user.purchased_wcclasses.addToSet wcclass
              user.save()
              console.log user
              if err
                console.log err
                return res.send "error saving purchase record in db, sorry. email dev@wileycousins.com and complain"
              console.log i
              if i <= 0
                mailer.newPurchase user
                return res.render 'purchase', user:user

  app.get "/my-classes", (req, res) ->
    console.log !req.query.email
    if !req.query.email
      return res.render "getEmail.jade"
    Users.find( email: req.query.email ).populate('purchased_wcclasses').exec (err, users) ->
      if err
        return res.render "error.jade", error: err
      if users.length == 0
        return res.render "getEmail.jade", error:"Didn't find an account for <span class='blue'>#{req.query.email}</span><br>you sure you signed up?<br>If you are having problems email <a href='mailto:dev@wileycousins.com'> wiley cousins</a>"
      user = users[0]
      WCClass.find( buyer: user, has_paid: true ).exec (err, wcclasses) ->
        if err
          return res.render "error.jade", error: err
        return res.render "my_classes.jade",
          user:user
          wcclasses: wcclasses

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

  app.get "/orders", isAdmin, (req, res) ->
    Users.find().populate('purchased_wcclasses').exec (err, users) ->
      if err
        console.log err
        return res.send err
      users.sort (a,b) ->
        a.purchased_wcclasses[0]?.purchase_date - b.purchased_wcclasses[0]?.purchase_date
      return res.render "orders.jade", users: users

  app.get "/purchase", isAdmin, (req, res) ->
    WCClass.find().exec (err, wcclasses) ->
      if err
        console.log err
      return res.render 'purchase', num: wcclasses.length

  app.get "/confirmation", isAdmin, (req, res) ->
    Users.findOne().exec (err, user) ->
      if err
        console.log err
      WCClass.find().exec (err, wcclasses) ->
        if err
          console.log err
        return res.render 'emailTemplates/confirmation',
          user: user
          num: wcclasses.length
          wcclass: wcclasses[wcclasses.length - 1]
          url: 'http://127.0.0.1:3000'

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
