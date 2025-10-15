import process from "node:process";
import { serve } from "@hono/node-server";
import { consola } from "consola";
import { Hono } from "hono";
import "dotenv/config";

const app = new Hono();

app.get("/health", (context) => {
    return context.json({
        ok: true,
        timestamp: Date.now(),
    });
});

const server = serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        consola.log(`Server is running on http://localhost:${info.port}`);
    },
);

process.on("SIGINT", () => {
    server.close();
    process.exit(0);
});

process.on("SIGTERM", () => {
    server.close((error) => {
        if (error) {
            consola.error(error);
            process.exit(1);
        }

        process.exit(0);
    });
});
