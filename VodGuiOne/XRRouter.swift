//
//  XRRouter.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 22/02/2024.
//

import Foundation
enum XRRouter: String, Identifiable, CaseIterable, Equatable {
    var id: Self { self }
    
    case wall, sphere, curved
    
}
