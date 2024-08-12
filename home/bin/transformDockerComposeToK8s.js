var readline = require('readline');

var input = [];

var result = "";

var rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.prompt();

rl.on('line', function (cmd) {
    if (cmd == "") return
    let name, value;
    if(cmd.includes('- ')) {
        [ name, value ] = cmd.split('- ')[1].split('=')
    } else {
        [ name, value ] = cmd.split(': ')
    }
    result += `- name: ${name.trim()}\n  value: ${value.trim()}\n`
});

rl.on('close', function (cmd) {
    console.log(result)
    process.exit(0);
});
