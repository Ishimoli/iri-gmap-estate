const express = require('express');
const fs = require('fs');
const multer = require('multer');
const app = express();
const auth = require('basic-auth');
const bodyParser = require('body-parser');
const payjp = require('payjp')("sk_test_44de5c1d88af6bfa9264c0f9");
const https = require('https');
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

//const payjp = require('payjp')(process.env.PAYJP_TEST_SECRET_KEY);

const { exec } = require('child_process')

const admins = {
    // TODO パスワードがありえないことになっているのでハッシュ値にする
    'user': { password: 'pass' },
};

admin.initializeApp({
    // 認証
    credential: admin.credential.cert(serviceAccount),
    // ストレージ
    storageBucket: "estplante.appspot.com",
    // FirestoreDB名
    databaseURL: "https://direct-video.firebaseio.com",
});

app.use(bodyParser.urlencoded({
    extended: true
}));

app.use(bodyParser.json());

// curl -u user:pass -d id="6HEFJLpcxhQ3dhlyRAu7ghitIYp1" -X POST http://localhost:3000/card
app.post('/cards', async (request, response) => {
    // // basic auth
    // const user = auth(request);
    // if (!user || !admins[user.name] || admins[user.name].password !== user.pass) {
    //     return response.status(401).send();
    // }
    const { id } = request.body
    if (!id) {
        response.status(400).json({ message: 'Card not found.' }).end()
        return
    }
    const customerCards = await getCustomerCards(id);
    if (customerCards.count > 0) {
        response.status(200).json(customerCards)
        return
    }
    response.status(404).json(customerCards)
})

app.post('/cards/save', async (request, response) => {
    const { card, id, email } = request.body
    if (!(card || id || email)) {
        response.status(400).json({ message: 'Card not found.' }).send()
    }
    try {
        const customer = await payjp.customers.create(request.body);
        response.status(201).json(customer);
    }
    catch (e) {
        const { error } = JSON.parse(e.response.text);
        console.warn('payjp error', error);
        response.status(e.status).json({ message: error.message });
    }
})

app.post('/cards/pay', async (request, response) => {
    const { card, id, email, amount } = request.body
    if (!(card || id || email || amount)) {
        response.status(400).json({ message: 'Card not found.' }).send()
    }
    try {
        const charge = await payjp.charges.create({
            amount: amount,
            currency: 'jpy',
            customer: id
        });
        response.status(201).json(charge);
    }
    catch (e) {
        const { error } = JSON.parse(e.response.text);
        console.warn('payjp error', error);
        response.status(e.status).json({ message: error.message });
    }
})

app.post('/video/converter', multer({ dest: 'tmp/' }).single('file'), (req, res) => {
    // basic auth
    const user = auth(req);
    if (!user || !admins[user.name] || admins[user.name].password !== user.pass) {
        return res.status(401).send();
    }

    console.log("file uploaded:", req.file.path);
    exec('ffmpeg -i ' + req.file.path + ' -vf hflip ' + req.file.path + '.mp4', (err, stdout, stderr) => {
        if (err) {
            console.error(stderr)
            return res.status(500).send();
        }

        res.writeHead(200, {
            'Content-Length': fs.statSync(req.file.path + '.mp4').size,
            'Content-Type': 'video/mp4'
        });
        var readStream = fs.createReadStream(req.file.path + '.mp4');
        readStream.pipe(res);
    })
});

app.post('/video/upload', multer({ dest: 'tmp/' }).single('file'), (req, res) => {
    // basic auth
    const user = auth(req);
    if (!user || !admins[user.name] || admins[user.name].password !== user.pass) {
        return res.status(401).send();
    }
    uploadFileToGCS(req.file.path, res);
});

const uploadFileToGCS = (filePath, res) => {
    console.log("uploadFileToGCS:", filePath);

    const bucket = admin.storage().bucket("estplante.appspot.com");

    bucket.upload(filePath)
        .then((uploadResponse) => {
            console.log(uploadResponse[0].metadata.name);
            res.status(200).json({ video: uploadResponse[0].metadata.name }).send()
        })
        .catch(err => {
            console.error(err);
        });
}

// curl -o converted.mp4 -u 6HEFJLpcxhQ3dhlyRAu7ghitIYp1:a7744b7a65564522c3485e803e597d50 -X GET http://localhost:3000/video/get
app.get('/video/get', async (req, res) => {
    // basic auth
    const user = auth(req);
    if (!user || !user.name || !user.pass) {
        return res.status(400).json({ message: 'not found.' }).end();
    }

    console.log("userId/videoId:", user.name, user.pass);

    var db = admin.firestore();
    let query = await db.collection('Order')
        .where('video', '=', user.pass)
        .get();

    if (query.size == 0) {
        return res.status(400).json({ message: 'not found.' }).end();
    }
    query.forEach(doc => {
        let orderer = doc.data().orderer;
        let provider = doc.data().provider;
        console.log(orderer, provider);
        if (user.name == orderer || user.name == provider) {
            downloadFile(res, user.pass);
            return;
        }
        return res.status(400).json({ message: 'not found.' }).end();
    });
});

const downloadFile = async (res, path) => {
    const bucket = admin.storage().bucket("estplante.appspot.com");
    var r = await bucket.file(path).download();
    fs.writeFileSync("tmp/" + path + '.mp4', r[0], (err) => {
        if (err) {
            console.error(err);
            return;
        }
        console.log('file write on finished');
    });
    res.writeHead(200, {
        'Content-Length': fs.statSync("tmp/" + path + '.mp4').size,
        'Content-Type': 'video/mp4'
    });
    var readStream = fs.createReadStream("tmp/" + path + '.mp4');
    readStream.pipe(res);
}

const getCustomerCards = async id => {
    console.log("getCustomerCards:", id);
    return new Promise((resolve, reject) => {
        https.get({
            "host": "api.pay.jp",
            "port": 443,
            "path": "/v1/customers/" + id,
            "auth": "sk_test_44de5c1d88af6bfa9264c0f9:"
        }
            , function (res) {
                if (res.statusCode >= 400 && res.statusCode != 404) {
                    console.warn('payjp error', '/v1/customers/' + id, res.statusCode)
                    return
                }
                var data = ''
                res.on('data', function (chunk) {
                    data += chunk
                })
                res.on('end', function () {
                    if (res.statusCode == 404) {
                        resolve({ cards: [], count: 0, default: "" })
                        return
                    }
                    console.log(data)
                    const { cards, default_card } = JSON.parse(data)
                    resolve({ cards: cards.data, count: cards.count, default: default_card })
                })
            })
    });
};

// 存在しないページはNOTFOUND
app.use(function (req, res) {
    res.status(404);
    res.end('<h1>404 - Not Found</h1>');
})

// ローカルの場合ポート3000でサーバを立てる
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`App listening on port ${PORT}`, 'Press Ctrl+C to quit.'))
