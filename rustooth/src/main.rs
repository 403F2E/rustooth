use bluer::rfcomm::{Listener, SocketAddr};
use std::env;
use std::fs::OpenOptions;
use std::io::{Read, Write};
use std::path::Path;
use tokio::io::{AsyncBufReadExt, AsyncReadExt, AsyncWriteExt, BufReader};
use tokio::task;

const CHANNEL: u8 = 1;
const HELLO_MSG: &[u8] = b"Hello from rustooth\n";

#[tokio::main]
async fn main() -> bluer::Result<()> {
    // Program supports two modes:
    // 1) If a /dev/rfcommX device exists (or user passes `dev:/path` as first arg), we open it
    //    and communicate over the serial device (useful when the connection is already bound
    //    to a TTY by external tools).
    // 2) Otherwise we run an RFCOMM Listener and accept the connection from the allowed Bluetooth
    //    address provided as the first argument (AA:BB:CC:DD:EE:FF).
    //
    // Usage:
    //  - Automatic serial mode detection: `cargo run` (if /dev/rfcomm0 exists)
    //  - Explicit serial device: `cargo run -- dev:/dev/rfcomm0`
    //  - RFCOMM listener mode: `cargo run -- AA:BB:CC:DD:EE:FF`
    let args: Vec<String> = env::args().collect();

    // Determine serial path:
    let explicit_dev: Option<String> = args.get(1).and_then(|s| {
        if s.starts_with("dev:") {
            Some(s["dev:".len()..].to_string())
        } else if s.starts_with('/') {
            Some(s.clone())
        } else {
            None
        }
    });

    // If explicit device provided, use it. Otherwise, auto-detect /dev/rfcomm0.
    let serial_device = if let Some(dev) = explicit_dev {
        Some(dev)
    } else if Path::new("/dev/rfcomm0").exists() {
        Some("/dev/rfcomm0".to_string())
    } else {
        None
    };

    if let Some(dev_path) = serial_device {
        println!("Operating in serial (/dev) mode using device: {}", dev_path);

        // Spawn blocking work to interact with the serial device using std::fs IO.
        // This avoids needing extra crates for async serial; it's adequate when the device
        // is already bound and behaves as a TTY.
        let dev = dev_path.clone();
        let res = task::spawn_blocking(move || -> std::io::Result<()> {
            // Open for read and write. If this fails, return the error to be printed below.
            let mut f = OpenOptions::new().read(true).write(true).open(&dev)?;

            // Send hello right away.
            if let Err(e) = f.write_all(HELLO_MSG) {
                eprintln!("Failed to write hello to {}: {}", dev, e);
                return Err(e);
            }
            let _ = f.flush();

            let mut buf = [0u8; 1024];
            loop {
                match f.read(&mut buf) {
                    Ok(0) => {
                        println!("Serial device closed (EOF)");
                        break;
                    }
                    Ok(n) => {
                        println!("Read {} bytes from serial device", n);
                        // Echo them back
                        if let Err(e) = f.write_all(&buf[..n]) {
                            eprintln!("Failed to write to serial device: {}", e);
                            break;
                        }
                        let _ = f.flush();
                    }
                    Err(e) => {
                        eprintln!("Serial read error: {}", e);
                        break;
                    }
                }
            }

            Ok(())
        })
        .await;

        match res {
            Ok(Ok(())) => {
                println!("Serial session finished normally.");
            }
            Ok(Err(e)) => {
                eprintln!("Serial session IO error: {}", e);
            }
            Err(join_err) => {
                eprintln!("Serial task panicked or was cancelled: {}", join_err);
            }
        }

        return Ok(());
    }

    // No serial device; expect an allowed Bluetooth address as the first arg.
    if args.len() < 2 {
        eprintln!("No serial device found and no allowed Bluetooth address provided.");
        eprintln!("Usage examples:");
        eprintln!("  cargo run -- dev:/dev/rfcomm0        # explicit serial device");
        eprintln!("  cargo run -- AA:BB:CC:DD:EE:FF      # RFCOMM listener mode");
        return Ok(());
    }
    let allowed_addr = args[1].to_uppercase();

    let session = bluer::Session::new().await?;
    let adapter = session.default_adapter().await?;
    adapter.set_powered(true).await?;
    adapter.set_discoverable(true).await?;
    let adapter_addr = adapter.address().await?;

    let local_sa = SocketAddr::new(adapter_addr, CHANNEL);
    let listener = Listener::bind(local_sa).await?;

    println!(
        "Listening on {} channel {}. Press enter to quit.",
        listener.as_ref().local_addr()?.addr,
        listener.as_ref().local_addr()?.channel
    );

    let stdin = BufReader::new(tokio::io::stdin());
    let mut lines = stdin.lines();

    loop {
        println!("\nWaiting for connection...");

        let (mut stream, sa) = tokio::select! {
            l = listener.accept() => {
                match l {
                    Ok(v) => v,
                    Err(err) => {
                        println!("Accepting connection failed: {}", &err);
                        continue;
                    }
                }
            },
            _ = lines.next_line() => break,
        };

        // Allow exactly one pre-authorized Android device to connect.
        let remote_addr = sa.addr.to_string().to_uppercase();
        if remote_addr != allowed_addr {
            println!("Rejected connection from {} (not allowed)", &remote_addr);
            // Optionally inform the client then close.
            let _ = stream.write_all(b"Rejected: not authorized\n").await;
            let _ = stream.shutdown().await;
            continue;
        }

        println!("Accepted connection from {}", &remote_addr);
        println!("Sending hello");
        if let Err(err) = stream.write_all(HELLO_MSG).await {
            println!("Write failed: {}", &err);
            continue;
        }

        loop {
            let buf_size = 1024;
            let mut buf = vec![0; buf_size as _];

            let n = match stream.read(&mut buf).await {
                Ok(0) => {
                    println!("Stream ended");
                    break;
                }
                Ok(n) => n,
                Err(err) => {
                    println!("Read failed: {}", &err);
                    break;
                }
            };
            let buf = &buf[..n];

            println!("Echoing {} bytes", buf.len());
            if let Err(err) = stream.write_all(&buf).await {
                println!("Write failed: {}", &err);
                continue;
            }
        }

        // After the authorized device disconnects, stop the server (exactly one device allowed).
        println!("Authorized device disconnected — exiting.");
        break;
    }

    Ok(())
}
