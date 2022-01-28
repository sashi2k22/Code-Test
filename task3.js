let obj = {
    a1: {
        b1: {
            nested: true
        },
    },
    x1: {
        y1: 'zl',
    }
};


function getObjectKeys(object, key) {
    // if you want another split key you can change this.
    const keys = key.split('.');
    let obj = object;
    for (let ikey of keys) {
        for (let [objKey, value] of Object.entries(obj)) {
            if(!keys.includes(objKey)) {
                continue;
            }
            obj = value;
        }
    }
    return obj;
}

console.log(getObjectKeys(obj, 'a1.b1.nested'));

console.log(getObjectKeys(obj, 'x1.y1'));
// even if there is another additional key
console.log(getObjectKeys(obj, 'x1.y1.nested'));