config   = require './config'
mongoose = require 'mongoose'
Schema = mongoose.Schema

WCClass = new Schema
  name:
    type: String
    default: "processing"
  #prices:
    #one:
      #type: Number
      #default: 7.52
    #four:
      #type: Number
      #default: 20.91
    #twelve:
      #type: Number
      #default: 51.80
  image:
    type: String
    default: "http://wileycousins.com/images/processing.jpg"
  purchase_date:
    type: Date
    default: (new Date()).toJSON()
  buyer:
    type: Schema.ObjectId
    ref: 'User'

User = new Schema
  email:
    type      : String
    required  : true
  name: String
  phone: String
  address: String
  city: String
  state: String
  zip: String
  purchased_wcclasses: [
    type: Schema.ObjectId
    ref: 'WCClass'
  ]

exports.User = mongoose.model 'User', User
exports.WCClass = mongoose.model 'WCClass', WCClass
