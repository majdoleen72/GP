import asyncio
from bleak import BleakScanner, BleakClient

NAME = "RiderShield-Helmet"
CHAR = "12345678-1234-5678-1234-56789abcdef1"

async def main():
    print("Searching...")
    device = await BleakScanner.find_device_by_name(NAME, timeout=10)

    if device is None:
        print("NOT FOUND")
        return

    print("FOUND")

    async with BleakClient(device) as client:
        print("CONNECTED")
        await client.write_gatt_char(
            CHAR,
            b"MEDIUM",
            response=True
        )
        print("SENT MEDIUM")

asyncio.run(main())