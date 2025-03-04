#include <iostream>
#include <string>
#include <sstream>
#include <iomanip>
#include <algorithm>
using namespace std;

// Convert a string to its hexadecimal representation
string toHex(const string& input) {
    stringstream hexStream;
    for (unsigned char c : input) {
        hexStream << hex << setw(2) << setfill('0') << static_cast<int>(c);
    }
    return hexStream.str();
}

// Convert a hexadecimal string back to its original representation
string fromHex(const string& hexInput) {
    string output;
    for (size_t i = 0; i < hexInput.length(); i += 2) {
        string byte = hexInput.substr(i, 2);
        char c = static_cast<char>(stoi(byte, nullptr, 16));
        output += c;
    }
    return output;
}

// Custom encryption function
string encrypt(const string& plaintext, char key) {
    string encrypted = "";
    for (char c : plaintext) {
        encrypted += c ^ key;  // XOR encryption
    }
    reverse(encrypted.begin(), encrypted.end());  // Reverse the string
    return toHex(encrypted);  // Return as hex for readability
}

// Custom decryption function
string decrypt(const string& hexCiphertext, char key) {
    string ciphertext = fromHex(hexCiphertext);  // Convert hex back to original
    reverse(ciphertext.begin(), ciphertext.end());  // Reverse back
    string decrypted = "";
    for (char c : ciphertext) {
        decrypted += c ^ key;  // XOR decryption
    }
    return decrypted;
}

int main() {
    string plaintext;
    char key;

    cout << "Enter plaintext: ";
    getline(cin, plaintext);

    cout << "Enter a single character as key: ";
    cin >> key;

    string encrypted = encrypt(plaintext, key);
    cout << "Encrypted text: " << encrypted << endl;

    // Access control for decryption
    int accessCode;
    int attempts = 3;
    bool accessGranted = false;

    while (attempts > 0) {
        cout << "Enter access code to decrypt (Attempts left: " << attempts << "): ";
        cin >> accessCode;

        if (accessCode == 1234) {
            accessGranted = true;
            break;
        } else {
            cout << "Incorrect access code." << endl;
            attempts--;
        }
    }

    if (accessGranted) {
        string decrypted = decrypt(encrypted, key);
        cout << "Decrypted text: " << decrypted << endl;
    } else {
        cout << "Access denied. Exiting program." << endl;
    }

    return 0;
}
