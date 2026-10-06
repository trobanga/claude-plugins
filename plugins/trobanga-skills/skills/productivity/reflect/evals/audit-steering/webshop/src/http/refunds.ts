import { Router } from "express";

export const refunds = Router();
refunds.post("/", (_req, res) => res.status(202).end());
