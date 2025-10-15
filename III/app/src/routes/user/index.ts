import { Hono } from "hono";
import { router as _get } from "@/routes/user/index.get";

export const router = new Hono().basePath("/user");

router.route("/", _get);
