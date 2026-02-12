//
//  SplashScreenView.swift
//  KnitAndCalc
//
//  Splash screen shown for 2 seconds on cold launch
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26))

                Text("Knit&Calc")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}
