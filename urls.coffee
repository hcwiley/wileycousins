models    = require './models'
config    = require './config'
stripe    = require('stripe')(config.stripe)
Users     = models.User
WCClass     = models.WCClass
mailer    = require './mailer'

enrollUser = (req) ->

module.exports = (app) ->
  # UI routes 
  app.get "/", (req, res) ->
    res.render "index.jade"

  app.get "/work", (req, res) ->
    res.render "work.jade",
      title: "Our Work | Wiley Cousins"

  app.get "/classes", (req, res) ->
    res.render "classes.jade",
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
    classes = req.body.amount

    if !address
      enrollUser(req)
    else
      amount = 0
      if classes == '1'
        amount = 7.52
      else if classes == '4'
        amount = 20.91
      else if classes == '12'
        amount = 51.80
      else
        return res.send "not a good amount"
      stripeToken = req.body.stripeToken
      charge =
        description: "#{name} <#{email}> (#{phone}) @ #{address}, #{city}, #{state}, #{zip}"
        amount: amount*100
        currency: 'USD'
        card: stripeToken

      console.log charge

      Users.findOne(
        name: name
        email: email
        phone: phone
        address: address
        city: city
        state: state
        zip: zip
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
            return res.render 'error'
          else
            wcclass = new WCClass buyer: user, name: req.body.class
            wcclass.save (err, wcclass) ->
              if err
                console.log err
                return res.send "error creating purchase record in db, sorry"
              user.purchased_wcclasses.addToSet wcclass
              user.save (err, user) ->
                if err
                  console.log "error saving user post add wcclass: #{err}"
                WCClass.find( purchase_date: {$lt:(new Date()).toJSON()} ).exec (err, wcclasses)->
                  mailer.newPurchase user, wcclasses.length
                  return res.render 'purchase', num: wcclasses.length
  
  isAdmin = (req, res, next) -> 
    if process.env.NODE_ENV.match('wcclassion') && (!req.session.auth?.match('so-good') && !req.body.password?.match(process.env.ADMIN_PASSWORD))
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
        a.purchased_wcclasses[0].purchase_date - b.purchased_wcclasses[0].purchase_date
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
        return res.render 'emailTemplates/confirmation', user: user, num: wcclasses.length, url: 'http://127.0.0.1:3000'

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
