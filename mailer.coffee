nodemailer  = require 'nodemailer'
config      = require './config'
jade        = require 'jade'
fs          = require 'fs'

newPurchaseTemplate = jade.compile fs.readFileSync "./views/emailTemplates/newPurchase.jade"
confirmationTemplate = jade.compile fs.readFileSync "./views/emailTemplates/confirmation.jade"
errorTemplate = jade.compile fs.readFileSync "./views/emailTemplates/error.jade"


# create reusable transport method (opens pool of SMTP connections)
smtpTransport = nodemailer.createTransport "SMTP",
  host: "smtp.webfaction.com"
  port: 465
  secureConnection: true
  auth:
    user: "robot_wileycousins"
    pass: config.emailPW

# setup e-mail data with unicode symbols
mailOptions =
  from: "Wiley Cousins <robot@wileycousins.com>"
  to: "le dudes <dev@wileycousins.com>"
  subject: "wiley cousins class"

# send them an email
exports.confirmation = (user) ->
  mailOptions.to = user.email
  mailOptions.subject = 'wiley cousins class enrollment confirmation'
  wcclass = user.purchased_wcclasses[0]
  mailOptions.html = confirmationTemplate
      user: user
      wcclass: wcclass
      url: config.url
  smtpTransport.sendMail mailOptions, (error, res) ->
    if error
      console.log error
      exports.sendEmailError error, res
    else
      console.log "Message sent: " + res.message

# send us an email
exports.newPurchase = (user) ->
  mailOptions.subject = '[wc class] new enrollment'
  mailOptions.to = "le dudes <cole@wileycousins.com>"
  wcclasses = user.purchased_wcclasses
  mailOptions.html = newPurchaseTemplate
      user: user
      url: config.url
      wcclasses: wcclasses
  if process.env.NODE_ENV == 'production' || true
    smtpTransport.sendMail mailOptions, (error, res) ->
      if error
        console.log error
      else
        console.log "Message sent: " + res.message
  exports.confirmation user

# send us an email if we got an error emailing them
exports.sendEmailError = (error, req) ->
  mailOptions.to = "HALP <cole@wileycousins.com>"
  mailOptions.html = errorTemplate
      url: config.url
      error: error
      req: req
  mailOptions.subject = '[wc class] [error] send mail error'
  smtpTransport.sendMail mailOptions, (error, res) ->
    if error
      console.log error
    else
      console.log "Message sent: " + res.message
