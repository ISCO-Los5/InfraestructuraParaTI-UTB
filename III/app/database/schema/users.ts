import { int, mysqlTable, timestamp, varchar } from "drizzle-orm/mysql-core";

export const users = mysqlTable("users", () => ({
    id: int().autoincrement().primaryKey(),
    name: varchar({ length: 255 }).notNull(),
    age: int().notNull(),
    email: varchar({ length: 255 }).notNull().unique(),
    createdAt: timestamp().defaultNow(),
}));
