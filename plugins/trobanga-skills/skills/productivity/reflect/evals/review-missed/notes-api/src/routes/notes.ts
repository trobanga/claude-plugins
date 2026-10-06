import { Router } from "express";
import { saveNote } from "../store";

export const notes = Router();
notes.post("/", async (req, res) => {
  await saveNote(req.body);
  res.status(201).end();
});
