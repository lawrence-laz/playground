using QRCoder;
using System.IO;

QRCodeGenerator qrGenerator = new QRCodeGenerator();
QRCodeData qrCodeData = qrGenerator.CreateQrCode("https://www.google.com/", QRCodeGenerator.ECCLevel.Q);
PngByteQRCode qrCode = new PngByteQRCode(qrCodeData);
byte[] qrCodeAsPngByteArr = qrCode.GetGraphic(20);


File.WriteAllBytes("qr.png", qrCodeAsPngByteArr);
