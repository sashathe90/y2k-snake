//
//  JohnnySplashView.swift
//  RetroSnake
//
//  Created by Sasha The on 10/05/2026.
//

import Foundation

//
//  JohnnySplashView.swift
//  RetroSnake
//
//  Created by Sasha The on 10/05/2026.
//

import SwiftUI

struct JohnnySplashView: View {
    @State private var bootLineVisible = false
    @State private var cameraVisible = false
    @State private var eyesOffset: CGFloat = 0
    @State private var handOffsetX: CGFloat = 120
    @State private var handOffsetY: CGFloat = 60
    @State private var handOpacity: Double = 0
    @State private var emberGlow = false
    @State private var smokeAmount: CGFloat = 0
    @State private var titleVisible = false
    @State private var screenFlicker = false
    
    private let lcdColor = Color(red: 0.61, green: 0.67, blue: 0.43)
    private let inkColor = Color.black.opacity(0.78)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if bootLineVisible {
                    Rectangle()
                        .fill(lcdColor.opacity(0.9))
                        .frame(width: geometry.size.width * 0.86, height: 2)
                        .opacity(cameraVisible ? 0 : 1)
                }
                
                lcdPanel(size: geometry.size)
                    .opacity(cameraVisible ? 1 : 0)
                    .scaleEffect(cameraVisible ? 1 : 0.96)
                    .animation(.easeOut(duration: 0.35), value: cameraVisible)
                    .overlay {
                        if screenFlicker {
                            Color.black.opacity(0.18)
                        }
                    }
            }
            .onAppear {
                runSplashAnimation()
            }
        }
    }
    
    func lcdPanel(size: CGSize) -> some View {
        ZStack {
            lcdColor
                .ignoresSafeArea()
            
            VStack(spacing: 22) {
                Spacer(minLength: 22)
                
                ZStack {
                    johnnyCameraLogo()
                        .frame(width: min(size.width * 0.78, 340), height: min(size.width * 0.58, 260))
                    
                    handWithJoint()
                        .frame(width: min(size.width * 0.38, 170), height: min(size.width * 0.24, 110))
                        .offset(x: handOffsetX, y: handOffsetY)
                        .opacity(handOpacity)
                }
                .frame(height: min(size.height * 0.48, 330))
                
                smokeOverlay()
                    .frame(height: 120)
                    .opacity(Double(smokeAmount))
                
                Text("JOHNNY PLAYS")
                    .font(.system(size: min(size.width * 0.085, 38), weight: .black, design: .monospaced))
                    .foregroundColor(inkColor)
                    .tracking(2)
                    .opacity(titleVisible ? 1 : 0)
                    .scaleEffect(titleVisible ? 1 : 0.94)
                    .animation(.easeOut(duration: 0.35), value: titleVisible)
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 22)
            
            if smokeAmount > 0.55 {
                smokeFillScreen()
                    .opacity(Double((smokeAmount - 0.55) * 1.6))
            }
        }
    }
    
    func johnnyCameraLogo() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Camera arm / mount
                RoundedRectangle(cornerRadius: 3)
                    .stroke(inkColor, lineWidth: w * 0.018)
                    .frame(width: w * 0.16, height: h * 0.36)
                    .offset(x: -w * 0.38, y: h * 0.18)
                
                Rectangle()
                    .fill(inkColor)
                    .frame(width: w * 0.30, height: h * 0.045)
                    .offset(x: -w * 0.28, y: h * 0.16)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(inkColor)
                    .frame(width: w * 0.08, height: h * 0.42)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -w * 0.10, y: h * 0.29)
                
                Circle()
                    .stroke(inkColor, lineWidth: w * 0.017)
                    .frame(width: w * 0.10, height: w * 0.10)
                    .offset(x: -w * 0.16, y: h * 0.26)
                
                // Camera body
                cameraBodyShape()
                    .stroke(inkColor, lineWidth: w * 0.018)
                    .frame(width: w * 0.72, height: h * 0.50)
                    .offset(x: w * 0.04, y: -h * 0.06)
                
                cameraBodyShape()
                    .fill(inkColor.opacity(0.16))
                    .frame(width: w * 0.72, height: h * 0.50)
                    .offset(x: w * 0.04, y: -h * 0.06)
                
                // Face panel
                RoundedRectangle(cornerRadius: 2)
                    .fill(inkColor)
                    .frame(width: w * 0.38, height: h * 0.30)
                    .offset(x: w * 0.16, y: -h * 0.01)
                
                // Letter J on side
                Text("J")
                    .font(.system(size: w * 0.13, weight: .black, design: .monospaced))
                    .foregroundColor(inkColor)
                    .offset(x: -w * 0.18, y: -h * 0.03)
                    .opacity(0.95)
                
                // Eyes
                eyePair(width: w, height: h)
                    .offset(x: w * 0.16 + eyesOffset, y: -h * 0.03)
                
                // Mouth
                Path { path in
                    path.move(to: CGPoint(x: w * 0.42, y: h * 0.58))
                    path.addQuadCurve(
                        to: CGPoint(x: w * 0.55, y: h * 0.57),
                        control: CGPoint(x: w * 0.49, y: h * 0.50)
                    )
                }
                .stroke(lcdColor, lineWidth: w * 0.018)
                
                Rectangle()
                    .fill(lcdColor)
                    .frame(width: w * 0.035, height: h * 0.17)
                    .rotationEffect(.degrees(12))
                    .offset(x: w * 0.33, y: h * 0.02)
            }
        }
    }
    
    func cameraBodyShape() -> some Shape {
        CameraBodyShape()
    }
    
    func eyePair(width w: CGFloat, height h: CGFloat) -> some View {
        HStack(spacing: w * 0.055) {
            eye(width: w, height: h)
            eye(width: w, height: h)
        }
    }
    
    func eye(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            Triangle()
                .fill(lcdColor)
                .frame(width: w * 0.10, height: h * 0.08)
                .rotationEffect(.degrees(180))
                .offset(y: -h * 0.02)
            
            Rectangle()
                .fill(lcdColor)
                .frame(width: w * 0.095, height: h * 0.035)
                .offset(y: h * 0.015)
            
            Rectangle()
                .fill(inkColor)
                .frame(width: w * 0.014, height: h * 0.022)
                .offset(x: eyesOffset * 0.12, y: h * 0.012)
        }
    }
    
    func handWithJoint() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Wrist
                RoundedRectangle(cornerRadius: 4)
                    .stroke(inkColor, lineWidth: w * 0.045)
                    .frame(width: w * 0.22, height: h * 0.34)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -w * 0.22, y: h * 0.22)
                
                // Palm
                RoundedRectangle(cornerRadius: 10)
                    .stroke(inkColor, lineWidth: w * 0.045)
                    .frame(width: w * 0.48, height: h * 0.46)
                    .rotationEffect(.degrees(-8))
                    .offset(x: w * 0.02, y: h * 0.04)
                
                // Fingers
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(inkColor, lineWidth: w * 0.035)
                        .frame(width: w * 0.12, height: h * 0.52)
                        .rotationEffect(.degrees(-63 + Double(index) * 8))
                        .offset(x: w * (0.05 + CGFloat(index) * 0.09), y: -h * 0.09)
                }
                
                // Joint
                Rectangle()
                    .fill(inkColor)
                    .frame(width: w * 0.58, height: h * 0.08)
                    .rotationEffect(.degrees(-6))
                    .offset(x: w * 0.28, y: -h * 0.10)
                
                // Ember
                Circle()
                    .fill(emberGlow ? Color.red.opacity(0.95) : inkColor)
                    .frame(width: w * 0.065, height: w * 0.065)
                    .offset(x: w * 0.58, y: -h * 0.12)
                    .scaleEffect(emberGlow ? 1.28 : 1.0)
            }
        }
    }
    
    func smokeOverlay() -> some View {
        ZStack {
            smokePuff(x: -65, y: 22, scale: 0.7, delay: 0.0)
            smokePuff(x: -25, y: -4, scale: 0.9, delay: 0.1)
            smokePuff(x: 22, y: 14, scale: 1.0, delay: 0.2)
            smokePuff(x: 65, y: -18, scale: 0.85, delay: 0.3)
            smokePuff(x: 105, y: 6, scale: 0.7, delay: 0.4)
        }
    }
    
    func smokeFillScreen() -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 22)
                    .stroke(inkColor.opacity(0.28), lineWidth: 3)
                    .frame(width: CGFloat(80 + index * 18), height: CGFloat(42 + index * 8))
                    .offset(
                        x: CGFloat((index % 4) * 42 - 70),
                        y: CGFloat((index / 4) * 70 - 80)
                    )
            }
        }
    }
    
    func smokePuff(x: CGFloat, y: CGFloat, scale: CGFloat, delay: Double) -> some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(inkColor.opacity(0.55), lineWidth: 3)
            .frame(width: 58 * scale, height: 36 * scale)
            .offset(
                x: x + smokeAmount * 18,
                y: y - smokeAmount * 42
            )
            .opacity(Double(smokeAmount) - delay)
    }
    
    func runSplashAnimation() {
        bootLineVisible = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            cameraVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            eyesOffset = 12
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            eyesOffset = -12
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.40) {
            eyesOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            handOpacity = 1
            handOffsetX = 70
            handOffsetY = 34
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.10) {
            handOffsetX = 34
            handOffsetY = 18
            emberGlow = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.55) {
            handOffsetX = 92
            handOffsetY = 46
            emberGlow = false
            withAnimation(.easeOut(duration: 1.1)) {
                smokeAmount = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.55) {
            handOpacity = 0
            titleVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            startFlickerBurst()
        }
    }
    
    func startFlickerBurst() {
        for index in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                screenFlicker.toggle()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) {
            screenFlicker = false
        }
    }
}

struct CameraBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.06))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.98, y: rect.minY + rect.height * 0.26))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.78))
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    JohnnySplashView()
}
