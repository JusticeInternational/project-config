module.exports = function (fastify, opts, done) {
    fastify.get('/fail500', async (request, reply) => {
        // Your code
        reply
          .code(500)
          .header('Content-Type', 'application/json; charset=utf-8')
          .send({ failed: '500' })
      });
    done()
}