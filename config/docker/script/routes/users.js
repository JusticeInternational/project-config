module.exports = function (fastify, opts, done) {
// Create user database
var count = 0;
const users = Array(100)
                .fill(0)
                .map((_, x) => ({
                    name: `User_${x}`,
                    id: `ID_${x}`,
                }));
    fastify.get("/users", async (request, reply) => {
        count = count + 1;
        //   console.log(`/users ${count}`)
        reply.send(users);
        });
    fastify.get("/user/:id", async (request, reply) => {
        count = count + 1;
        //   console.log(`/user/${request.params["id"]} ${count}`)
        reply.send(users.find((x) => x.id == request.params["id"]));
          });
    done()
}