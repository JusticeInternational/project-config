module.exports = function (fastify, opts, done) {
    var count = 0;
    fastify.get("/ping", async (request, reply) => {
        date = new Date().getTime();
        count = count + 1;
        console.log(`pong date -> ${date} count -> ${count}`);
        reply.send(`pong date -> ${date} count -> ${count}`);
    });
    done()
}