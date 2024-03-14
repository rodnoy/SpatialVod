//
//  MovieDetailView.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 05/03/2024.
//

import SwiftUI

struct MovieDetailView: View {
    var onButtonTap: () -> Void
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    onButtonTap()
                }) {
                    Image(systemName: "xmark")
                }
                Spacer()
                Text("Movie title")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    // speaker action
                }) {
                    Image(systemName: "speaker.wave.3.fill")
                }
            }
            .padding()
            
            Picker("Details", selection: .constant(1)) {
                Text("Détails").tag(1)
                Text("Casting").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.leading, .trailing])
            Divider()
            
            HStack {
                Text("Aventure | 2012 | 2h29mn")
                    .font(.subheadline)
                Spacer()
                //                        Image("imdb-logo") // Замените "imdb-logo" на имя вашего ресурса изображения
                Text("IMDb")
                    .font(.subheadline)
                // здесь можно добавить иконки, если они вам нужны
            }
            .padding()
            
            Text("Arthur Curry est né d'un père humain et d'une mère Atlante, la reine Atlanna qui a dû le laisser pour retrouver les siens. Bien des années plus tard, Arthur parcourt le Sahara avec son amie Mera à la recherche de l'Atlantide. Ils parviennent à leurs fins et découvrent que le destin du royaume des Sept Mers dépend d'Arthur.")
              .font(Font.custom("SF Pro", size: 17))
              .padding()
//              .foregroundColor(.white.opacity(0.23))
              .frame(maxWidth: .infinity, alignment: .topLeading)
            
            Spacer()
            
            Button(action: {
                // действие для кнопки просмотра трейлера
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Bande Annonce")
                        .bold()
//
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .background(.gray.opacity(0.2))
        .glassBackgroundEffect(in: .rect(cornerRadius: 15))
//        .frame(width: 500, height: 659)

//        .cornerRadius(15)
        
    }
}

#Preview {
    MovieDetailView(onButtonTap: {})
}

