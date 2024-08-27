import { VoskCap } from 'voskcap';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    VoskCap.echo({ value: inputValue })
}
