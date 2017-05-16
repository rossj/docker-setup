import { delay } from 'bluebird';

export async function getSomething() {
    delay(10);
    return 'NODE_ENV: ' + process.env.NODE_ENV;
}
