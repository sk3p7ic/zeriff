const fs = require('fs/promises');

async function readFileContents(path) {
  try {
    return await fs.readFile(path, { encoding: 'utf8' });
  } catch (err) {
    console.log(err);
    return "";
  }
}

async function sendFileContents(file1, file2) {
  const b = JSON.stringify({
    file1,
    file2
  });
  console.log(`\nSending JSON payload: ${b}\n`);
  const res = await fetch('http://localhost:5173/api', {
    method: "post",
    body: b,
    headers: { "Content-Type": "application/json" },
  });
  return res.json();
}

console.log("Running lorem ipsum tests...");
Promise.all([readFileContents('./test1.txt'), readFileContents('./test2.txt')]).then(vals => {
  sendFileContents(vals[0], vals[1]).then(r => console.log(`\nRecieved response: ${JSON.stringify(r)}\n`));
}).then(() => {
  console.log("Running foo bar tests...");
  sendFileContents("Foo bar", "Foo baz").then(r => console.log(`\nRecieved response: ${JSON.stringify(r)}\n`));
}).then(() => {
  console.log("Running improper payload tests...");
  sendFileContents("Foo bar", null).then(r => console.log(`\nRecieved response: ${JSON.stringify(r)}\n`));
});
