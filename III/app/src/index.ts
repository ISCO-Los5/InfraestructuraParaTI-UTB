import process from "node:process";
import { serve } from "@hono/node-server";
import { consola } from "consola";
import { Hono } from "hono";
import { router as _user } from "@/routes/user";

const app = new Hono();

app.get("/health", (context) => {
    return context.json({
        ok: true,
        timestamp: Date.now(),
    });
});

app.route("/api", _user);

const server = serve(
    {
        fetch: app.fetch,
        port: 3000,
    },
    (info) => {
        consola.log(`Server is running on http://localhost:${info.port}`);
        consola.log(process.env);
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
