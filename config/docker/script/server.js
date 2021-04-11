// app/index.js
const fastify = require("fastify")({ logger: true });
// Take port from env variable
const PORT = process.env.PORT || 3000;
const PREFIX = process.env.PREFIX || '/demo-app';

//
// register routes
fastify.register(require('./routes/ping'), { prefix: PREFIX })
fastify.register(require('./routes/users'), { prefix: PREFIX })
fastify.register(require('./routes/fail500'), { prefix: PREFIX })

fastify.register(require('./routes/ping'), { prefix: '/' })
fastify.register(require('./routes/users'), { prefix: '/' })
fastify.register(require('./routes/fail500'), { prefix: '/' })

// Run the server!
const start = async () => {
  try {
    count = 0;
    console.log(`Starting up server on port ${PORT} ${count}`)
    await fastify.listen(PORT, "0.0.0.0");
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};
start();