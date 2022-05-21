module.exports = function (fastify, opts, done) {
    var count = 0;
    fastify.get("/", async (request, reply) => {
        console.log(`welcome`);
        reply.send(`welcome`);
    });
    done()
}