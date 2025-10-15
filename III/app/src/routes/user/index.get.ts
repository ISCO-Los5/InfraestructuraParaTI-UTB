import { db, tables } from "@@/database/drizzle";
import { Hono } from "hono";

export const router = new Hono();

router.get("/", async (context) => {
    const users = await db.select().from(tables.users);

    return context.json(users, { status: 200 });
});
