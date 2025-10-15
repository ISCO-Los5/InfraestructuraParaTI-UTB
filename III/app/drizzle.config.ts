import process from "node:process";
import { defineConfig } from "drizzle-kit";
import "dotenv/config";

export default defineConfig({
    out: "./drizzle",
    schema: "./database/schema/index.ts",
    dialect: "mysql",
    dbCredentials: {
        host: process.env.MYSQL_HOST!,
        user: process.env.MYSQL_USER!,
        password: process.env.MYSQL_PASSWORD!,
        database: process.env.MYSQL_DATABASE!,
    },
});
