const localtunnel = require("localtunnel")
console.log("** LOADING MIDDLEWARE")

const promise = localtunnel({ port: 8080 })
promise.then((tunnel) => {
    console.log("Forwarding to: " + tunnel.url)
}, (err) => { console.error(err) })

module.exports = async function (req, res, next) {
    // const tunnel = await promise;
    next();

    // Serving locally, directly from localhost:
    // if (req.headers["x-forwarded-host"] || req.headers.host === "127.0.0.1:8080" || req.url !== "/" || req.headers.host.indexOf("localhost") >= 0) {
    //     next()
    //     // Serving when 'refered' from local tunnel
    // } else if (req.headers["referer"] && req.headers["referer"].indexOf(".lt") >= 0) {
    //     next()
    // } else {
    //     res.writeHead(302, {
    //         'Location': tunnel.url,
    //         'Bypass-Tunnel-Reminder': '1',
    //     })
    //     res.end()
    // }
};
