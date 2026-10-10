import "./style.css";
import { Elm } from "./Main.elm";

const node = document.getElementById("app");

if (node === null) {
  throw new Error("Cantrip: missing #app mount node in index.html");
}

Elm.Main.init({ node });
