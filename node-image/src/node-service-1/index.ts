import { getSomething } from '../lib/something';

async function run() {
    console.log('Hello from node-service-1');
    console.log(await getSomething());
}

run();
