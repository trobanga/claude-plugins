import { Router } from "express";
import { refunds } from "./refunds";

export const routes = Router();
routes.use("/refunds", refunds);
