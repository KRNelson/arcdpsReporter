import request from 'supertest'
import { expect } from 'chai'

import app from './../express'
import { server } from './../express'

describe('App', () => {
  /*
  before(done => {
    app.listen((err: unknown) => {
      if (err) return done(err)
      return done()
    })
  })
  */

  it('works properly', done => {
    request(app)
    .get('/')
    .expect(200, (err, res) => {
      if (err) return done(err)
      expect(res.text).to.be.equals('TypeScript With Express')
      return done()
    })
  })

  after(done => {
    server.close(() => { console.log("server closing..."); done() });
  })
})