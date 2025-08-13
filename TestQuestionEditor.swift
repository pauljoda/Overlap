import SwiftUI

struct TestEditor: View {
    @Binding var questions: [String]
    @State private var selection: Int? = 0
    
    var body: some View {
        Text("Test")
    }
}

#Preview {
    struct Wrapper: View {
        @State var questions = ["Test"]
        
        var body: some View {
            TestEditor(questions: $questions)
        }
    }
    
    return Wrapper()
}
