const session = require("express-session");
const PgSession = require("connect-pg-simple")(session);
const { pool } = require("./db");

const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000;

module.exports = session({
  store: new PgSession({ pool, tableName: "sessions" }),
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: THIRTY_DAYS, secure: true },
});
