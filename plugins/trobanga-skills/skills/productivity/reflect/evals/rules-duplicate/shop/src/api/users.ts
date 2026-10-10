import { Router } from "express";
import { newUser } from "./schemas";

export const users = Router();
users.post("/", (req, res) => {
  const parsed = newUser.safeParse(req.body);
  if (!parsed.success) return res.status(400).json(parsed.error.issues);
  res.status(201).json(parsed.data);
});
