//
//  startAnimation.swift
//  hotplace_finder
//
//  Created by 김석우 on 5/8/25.
//
// New File 1: LoadingView.swift
//


//import SwiftUI
//
//@ViewBuilder
//func datePickerSection(takenAt: Binding<Date>) -> some View {
//    DatePicker("촬영 시간 (선택)", selection: takenAt, displayedComponents: .dateAndTime)
//        .datePickerStyle(CompactDatePickerStyle())
//        .minuteInterval(60)
//        .padding(.horizontal)
//}

import SwiftUI

@ViewBuilder
func datePickerSection(takenAt: Binding<Date>) -> some View {
//    DatePicker("촬영 시간 (선택)", selection: takenAt, displayedComponents: [.date, .hourAndMinute])
//        .datePickerStyle(CompactDatePickerStyle())
//        .minuteInterval(60)
//        .padding(Edge.Set.horizontal)
    
//    DatePicker("촬영 시간 (선택)", selection: takenAt, displayedComponents: [.date, .hourAndMinute])
//        .datePickerStyle(GraphicalDatePickerStyle()) // ✅ 이 스타일에서는 minuteInterval 사용 가능
//        .minuteInterval(60)
//        .padding(.horizontal)
    
    VStack(alignment: .leading) {
        Text("촬영 시간 (선택)")
            .font(.headline)
        
        HStack{
            DatePicker("", selection: takenAt, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
            Spacer()
        }
    }
//    DatePicker("촬영 시간 (선택)", selection: takenAt, displayedComponents: [.date, .hourAndMinute])
//        .datePickerStyle(CompactDatePickerStyle())
//        .padding(.horizontal)
}
