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
exports.confirmation = (user, wcclass) ->
  mailOptions.to = user.email
  mailOptions.subject = 'wiley cousins class enrollment confirmation'
  mailOptions.html = confirmationTemplate
      user: user
      url: config.url
      wcclass: wcclass
  smtpTransport.sendMail mailOptions, (error, res) ->
    if error
      console.log error
      exports.sendEmailError user, num, error, res
    else
      console.log "Message sent: " + res.message

# send us an email
exports.newPurchase = (user, wcclass, wcclasses) ->
  mailOptions.subject = '[wc class] new enrollment'
  to: "le dudes <dev@wileycousins.com>"
  mailOptions.html = newPurchaseTemplate
      user: user
      wcclass: wcclass
      wcclasses: wcclasses
      url: config.url
  if process.env.NODE_ENV == 'production'
    smtpTransport.sendMail mailOptions, (error, res) ->
      if error
        console.log error
      else
        console.log "Message sent: " + res.message
  exports.confirmation user, wcclass

# send us an email if we got an error emailing them
exports.sendEmailError = (user, error, res) ->
  to: "HALP <dev@wileycousins.com>"
  mailOptions.html = errorTemplate
      user: user
      url: config.url
      error: error
      res: res
  mailOptions.subject = '[wc class] [error] send mail error'
  smtpTransport.sendMail mailOptions, (error, res) ->
    if error
      console.log error
    else
      console.log "Message sent: " + res.message
