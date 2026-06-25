//
//  ButtonStyles.swift
//  RetroSnake
//
//  Created by Sasha The on 05/05/2026.
//

import SwiftUI

struct RetroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 34, weight: .black, design: .monospaced))
            .foregroundColor(.black)
            .frame(width: 72, height: 72)
            .background(Color(red: 0.58, green: 0.64, blue: 0.43))
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct PauseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .black, design: .monospaced))
            .foregroundColor(.black.opacity(0.78))
            .padding(.horizontal, 34)
            .padding(.vertical, 10)
            .background(Color(red: 0.58, green: 0.64, blue: 0.43))
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .black, design: .monospaced))
            .foregroundColor(.black.opacity(0.78))
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color(red: 0.58, green: 0.64, blue: 0.43))
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct CompactMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black, design: .monospaced))
            .foregroundColor(.black.opacity(0.78))
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .background(Color(red: 0.58, green: 0.64, blue: 0.43))
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct SmallMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 22, weight: .black, design: .monospaced))
            .foregroundColor(.black.opacity(0.78))
            .frame(width: 42, height: 42)
            .background(Color(red: 0.58, green: 0.64, blue: 0.43))
            .overlay(
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct SmallTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .black, design: .monospaced))
            .foregroundColor(.black.opacity(0.78))
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.65 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
