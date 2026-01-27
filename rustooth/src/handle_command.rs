use rdev::{simulate, Button, EventType, Key};
use std::{process::Command, str, thread, time::Duration};

pub fn handle_command(command_str: &str) {
    println!("Received command: {}", command_str);

    match command_str {
        // Mouse clicks
        "LEFTCLICK" => simulate_mouse_click(Button::Left),
        "RIGHTCLICK" => simulate_mouse_click(Button::Right),
        "MIDDLECLICK" => simulate_mouse_click(Button::Middle),

        // Arrow keys
        "UP" => simulate_key(Key::UpArrow),
        "DOWN" => simulate_key(Key::DownArrow),
        "LEFT" => simulate_key(Key::LeftArrow),
        "RIGHT" => simulate_key(Key::RightArrow),

        // Power/special keys
        "ENTER" => simulate_key(Key::Return),
        "ESC" => simulate_key(Key::Escape),
        "SPACE" => simulate_key(Key::Space),
        "TAB" => simulate_key(Key::Tab),
        "BACKSPACE" => simulate_key(Key::Backspace),
        "DELETE" => simulate_key(Key::Delete),
        "WIN" => simulate_key(Key::MetaLeft),

        // ShortCuts
        "CTRL_C" => shortcuts(Key::ControlLeft, Key::KeyC),
        "CTRL_V" => shortcuts(Key::ControlLeft, Key::KeyV),
        "ALT_TAB" => shortcuts(Key::Alt, Key::Tab),

        // Media/Audio
        "VOLUME_UP" => {
            let _ = Command::new("pactl")
                .args(["set-sink-volume", "@DEFAULT_SINK@", "+5%"])
                .output();
        }
        "VOLUME_DOWN" => {
            let _ = Command::new("pactl")
                .args(["set-sink-volume", "@DEFAULT_SINK@", "-5%"])
                .output();
        }
        "MUTE" => {
            let _ = Command::new("pactl")
                .args(["set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                .output();
        }

        // Function keys
        "F1" => simulate_key(Key::F1),
        "F2" => simulate_key(Key::F2),
        "F3" => simulate_key(Key::F3),
        "F4" => simulate_key(Key::F4),
        "F5" => simulate_key(Key::F5),
        "F6" => simulate_key(Key::F6),
        "F7" => simulate_key(Key::F7),
        "F8" => simulate_key(Key::F8),
        "F9" => simulate_key(Key::F9),
        "F10" => simulate_key(Key::F10),
        "F11" => simulate_key(Key::F11),
        "F12" => simulate_key(Key::F12),

        _ => {
            // Check if the entire string is just letters/numbers/spaces/punctuations (for typing)
            if command_str
                .chars()
                .all(|c| c.is_alphanumeric() || c.is_whitespace() || c.is_ascii_punctuation())
            {
                type_string(command_str);
            } else {
                // It's an unknown command or contains special chars
                println!("Unknown or complex command: '{}'", command_str);
            }
        }
    }
}

fn simulate_key(key: Key) {
    // Press and release the key
    if let Err(e) = simulate(&EventType::KeyPress(key)) {
        println!("Error simulating key press: {:?}", e);
    }

    // Small delay to ensure proper key sequence
    thread::sleep(Duration::from_millis(50));

    if let Err(e) = simulate(&EventType::KeyRelease(key)) {
        println!("Error simulating key release: {:?}", e);
    }
}

fn simulate_mouse_click(button: Button) {
    // Press and release the mouse button
    if let Err(e) = simulate(&EventType::ButtonPress(button)) {
        println!("Error simulating mouse press: {:?}", e);
    }

    // Small delay for click
    thread::sleep(Duration::from_millis(50));

    if let Err(e) = simulate(&EventType::ButtonRelease(button)) {
        println!("Error simulating mouse release: {:?}", e);
    }
}

// function to simulate shortcuts used by keyboard
fn shortcuts(modifier: Key, main_key: Key) {
    // Press modifiers
    let _ = simulate(&EventType::KeyPress(modifier));
    thread::sleep(Duration::from_millis(20));

    // Press and release main key
    let _ = simulate(&EventType::KeyPress(main_key));
    thread::sleep(Duration::from_millis(50));
    let _ = simulate(&EventType::KeyRelease(main_key));
    thread::sleep(Duration::from_millis(20));

    // Release modifiers (often in reverse order)
    let _ = simulate(&EventType::KeyRelease(modifier));
    thread::sleep(Duration::from_millis(20));
}

fn type_string(text: &str) {
    println!("Typing string: {}", text);

    for ch in text.chars() {
        match ch {
            // Uppercase and lowercase letters
            'A'..='Z' | 'a'..='z' => {
                let key = letter_to_key(ch);
                simulate_key(key);
            }
            // Numbers
            '0'..='9' => {
                let key = number_to_key(ch);
                simulate_key(key);
            }
            // Space
            ' ' => simulate_key(Key::Space),

            _ => {
                println!("Character '{}' not yet supported for typing.", ch);
                continue;
            }
        }
        // A small delay between characters can improve reliability
        std::thread::sleep(std::time::Duration::from_millis(30));
    }
}

// Helper: Convert a digit char to the corresponding Key enum
fn letter_to_key(ch: char) -> Key {
    match ch.to_ascii_uppercase() {
        'A' | 'a' => Key::KeyA,
        'B' | 'b' => Key::KeyB,
        'C' | 'c' => Key::KeyC,
        'D' | 'd' => Key::KeyD,
        'E' | 'e' => Key::KeyE,
        'F' | 'f' => Key::KeyF,
        'G' | 'g' => Key::KeyG,
        'H' | 'h' => Key::KeyH,
        'I' | 'i' => Key::KeyI,
        'J' | 'j' => Key::KeyJ,
        'K' | 'k' => Key::KeyK,
        'L' | 'l' => Key::KeyL,
        'M' | 'm' => Key::KeyM,
        'N' | 'n' => Key::KeyN,
        'O' | 'o' => Key::KeyO,
        'P' | 'p' => Key::KeyP,
        'Q' | 'q' => Key::KeyQ,
        'R' | 'r' => Key::KeyR,
        'S' | 's' => Key::KeyS,
        'T' | 't' => Key::KeyT,
        'U' | 'u' => Key::KeyU,
        'V' | 'v' => Key::KeyV,
        'W' | 'w' => Key::KeyW,
        'X' | 'x' => Key::KeyX,
        'Y' | 'y' => Key::KeyY,
        'Z' | 'z' => Key::KeyZ,
        _ => panic!("Invalid letter"), // Should not happen
    }
}

// Helper: Convert a digit char to the corresponding Key enum
fn number_to_key(ch: char) -> Key {
    match ch {
        '0' => Key::Num0,
        '1' => Key::Num1,
        '2' => Key::Num2,
        '3' => Key::Num3,
        '4' => Key::Num4,
        '5' => Key::Num5,
        '6' => Key::Num6,
        '7' => Key::Num7,
        '8' => Key::Num8,
        '9' => Key::Num9,
        _ => panic!("Invalid digit"), // Should not happen
    }
}
