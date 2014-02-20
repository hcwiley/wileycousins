config   = require './config'
mongoose = require 'mongoose'
Schema = mongoose.Schema

WCClass = new Schema
  name:
    type: String
    default: "Processing"
  image:
    type: String
    default: "#{config.url}/images/p5.png"
  purchase_date:
    type: Date
    default: (new Date()).toJSON()
  buyer:
    type: Schema.ObjectId
    ref: 'User'
  been_used:
    type: Boolean
    default: false
  used_date:
    type: Date
  kit:
    type: Number
  has_paid:
    type: Boolean
    default: false

User = new Schema
  email:
    type      : String
    required  : true
    unique    : true
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
