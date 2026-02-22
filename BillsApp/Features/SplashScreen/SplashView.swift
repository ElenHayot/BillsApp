//
//  SplashView.swift
//  BillsApp
//
//  Created by Elen Hayot on 20/02/2026.
//

import SwiftUI

struct SplashView: View {
    
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var dotsOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0F1923"),
                    Color(hex: "162030"),
                    Color(hex: "0F1923")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle grid texture
            Canvas { context, size in
                let spacing: CGFloat = 40
                var path = Path()
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += spacing
                }
                context.stroke(path, with: .color(Color.white.opacity(0.03)), lineWidth: 0.5)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                Spacer()
                
                // Logo Zone
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "4AE89A").opacity(0.4), Color(hex: "2DD4BF").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 130, height: 130)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                    
                    // Inner ring
                    Circle()
                        .stroke(Color(hex: "4AE89A").opacity(0.15), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                    
                    // Logo background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1E2D3D"), Color(hex: "162030")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "4AE89A").opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "4AE89A").opacity(0.2), radius: 20, x: 0, y: 0)
                    
                    // Logo icon — pie chart + euro
                    LogoIcon()
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                Spacer().frame(height: 36)
                
                // App name
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("COMPTA")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(6)
                        Text("·VIZ")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(Color(hex: "4AE89A"))
                            .tracking(6)
                    }
                    
                    Text("Tes dépenses. Maîtrisées.")
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(Color.white.opacity(0.4))
                        .tracking(2)
                        .opacity(subtitleOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
                
                Spacer()
                
                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        LoadingDot(delay: Double(i) * 0.2)
                    }
                }
                .opacity(dotsOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
                ringScale = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.65)) {
                subtitleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.85)) {
                dotsOpacity = 1.0
            }
        }
    }
}

// MARK: - Logo Icon
struct LogoIcon: View {
    @State private var rotation: Double = -90
    
    var body: some View {
        ZStack {
            // Camembert stylisé
            PieSlice(startAngle: .degrees(0), endAngle: .degrees(130))
                .fill(Color(hex: "4AE89A").opacity(0.9))
                .frame(width: 42, height: 42)
            
            PieSlice(startAngle: .degrees(132), endAngle: .degrees(230))
                .fill(Color(hex: "2DD4BF").opacity(0.7))
                .frame(width: 42, height: 42)
            
            PieSlice(startAngle: .degrees(232), endAngle: .degrees(358))
                .fill(Color(hex: "0891B2").opacity(0.5))
                .frame(width: 42, height: 42)
            
            // Petit trou central (donut effect)
            Circle()
                .fill(Color(hex: "1E2D3D"))
                .frame(width: 16, height: 16)
            
            // Symbole €
            Text("€")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "4AE89A"))
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                rotation = 0
            }
        }
    }
}

// MARK: - Pie Slice Shape
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Loading Dot
struct LoadingDot: View {
    let delay: Double
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Circle()
            .fill(Color(hex: "4AE89A"))
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

// MARK: - Color Hex Extension
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let r = Double((int >> 16) & 0xFF) / 255
//        let g = Double((int >> 8) & 0xFF) / 255
//        let b = Double(int & 0xFF) / 255
//        self.init(red: r, green: g, blue: b)
//    }
//}

#Preview {
    SplashView()
}
