const fs = require("fs");
const path = require("path");

function getTheAbi(jsonPath) {
  try {
    const dir = path.resolve(__dirname, jsonPath);
    const file = fs.readFileSync(dir, "utf8");
    const json = JSON.parse(file);
    const abi = json.abi;
    return abi;
  } catch (error) {
    console.log(`error`, error);
  }
}

module.exports = {
  getTheAbi,
};
