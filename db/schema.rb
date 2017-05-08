# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170502232146) do

  create_table "expenses", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", force: :cascade do |t|
    t.text     "address"
    t.text     "url"
    t.float    "longitude"
    t.float    "latitude"
    t.float    "listingPrice"
    t.float    "bedrooms"
    t.float    "bathrooms"
    t.integer  "builtIn"
    t.boolean  "garage"
    t.datetime "lastConfirmed"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "rentals", force: :cascade do |t|
    t.float    "Price"
    t.float    "bedrooms"
    t.integer  "externalId"
    t.float    "longitude"
    t.float    "latitute"
    t.float    "pricePerRoom"
    t.datetime "lastConfirmed"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "statuses", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
