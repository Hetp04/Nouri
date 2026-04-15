//
//  CompareScreenView.swift
//  nouriapp
//

import SwiftUI
import Combine

// MARK: - Models

struct IngredientInfo: Identifiable {
    let id = UUID()
    let label: String
    let bad: Bool
}

struct ComparisonProduct {
    let title: String
    let subtitle: String
    let imageName: String
    let textMessage: String
    let baseColor: Color
    let imageScale: CGFloat
    let imageOffset: CGSize
    let ingredients: [IngredientInfo]
    
    static let pairs: [ComparisonPair] = [
        .init(bad: .lays, good: .siete),
        .init(bad: .frootLoops, good: .heritage)
    ]
}

struct ComparisonPair {
    let bad: ComparisonProduct
    let good: ComparisonProduct
}

// MARK: - View Model

@MainActor
class ComparisonViewModel: ObservableObject {
    @Published var currentPairIndex = 0
    @Published var isShowingGoodProduct = false
    @Published var is3DCardFlipped = false
    @Published var visibleIngredientCount = 0
    @Published var transitionEdge: Edge = .trailing
    @Published var containerTapScale: CGFloat = 1.0
    @Published var physicsTrigger = 0
    @Published var isPhysicsActive = false
    @Published var physicsSnapshots: [Int: CGRect] = [:] 
    
    let pairs: [ComparisonPair]
    private let onBack: () -> Void
    private let onNext: () -> Void
    
    init(pairs: [ComparisonPair], onBack: @escaping () -> Void, onNext: @escaping () -> Void, startAtLast: Bool) {
        self.pairs = pairs
        self.onBack = onBack
        self.onNext = onNext
        self.currentPairIndex = startAtLast ? max(0, pairs.count - 1) : 0
    }
    
    var currentPair: ComparisonPair { pairs[currentPairIndex] }
    var activeProduct: ComparisonProduct { isShowingGoodProduct ? currentPair.good : currentPair.bad }
    
    func toggleFlip() {
        let isFlippingFromBad = !isShowingGoodProduct
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        withAnimation(.easeOut(duration: 0.15)) { containerTapScale = 0.92 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                self.containerTapScale = 1.0
                self.is3DCardFlipped.toggle()
            }
            if isFlippingFromBad { 
                self.isPhysicsActive = true
                self.physicsTrigger += 1 
            } else {
                self.isPhysicsActive = false
            }
            self.isShowingGoodProduct.toggle()
        }
    }
    
    func next() { currentPairIndex < pairs.count - 1 ? update(idx: currentPairIndex + 1, edge: .trailing) : onNext() }
    func back() { currentPairIndex > 0 ? update(idx: currentPairIndex - 1, edge: .leading) : onBack() }
    
    private func update(idx: Int, edge: Edge) {
        transitionEdge = edge
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPairIndex = idx
            is3DCardFlipped = false; isShowingGoodProduct = false; isPhysicsActive = false
            physicsSnapshots = [:] // Wipe stale data instantly
            runStaggeredAnimation()
        }
    }
    
    func runStaggeredAnimation() {
        isPhysicsActive = false
        visibleIngredientCount = 0
        if isShowingGoodProduct { visibleIngredientCount = 100; return }
        
        let ingredients = currentPair.bad.ingredients
        let generator = UIImpactFeedbackGenerator(style: .light)
        for i in 0..<ingredients.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.04) {
                self.visibleIngredientCount = max(self.visibleIngredientCount, i + 1)
                if i < ingredients.count && ingredients[i].bad { generator.impactOccurred(intensity: 0.6) }
            }
        }
    }
}

// MARK: - Main View

struct CompareScreenView: View {
    @StateObject private var viewModel: ComparisonViewModel
    
    init(onBack: @escaping () -> Void = {}, onNext: @escaping () -> Void = {}, startAtLastProduct: Bool = false) {
        _viewModel = StateObject(wrappedValue: ComparisonViewModel(
            pairs: ComparisonProduct.pairs, onBack: onBack, onNext: onNext, startAtLast: startAtLastProduct
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                productHub
                breakdownHeader
            }
            .padding(.horizontal, 24)
            
            ZStack {
                IngredientListView(product: viewModel.currentPair.bad, isBadSide: true, viewModel: viewModel)
                    .opacity(viewModel.is3DCardFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(viewModel.is3DCardFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                
                IngredientListView(product: viewModel.currentPair.good, isBadSide: false, viewModel: viewModel)
                    .opacity(viewModel.is3DCardFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(viewModel.is3DCardFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .id("ingredient_list_\(viewModel.currentPairIndex)")
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: viewModel.transitionEdge)),
                removal: .opacity.combined(with: .move(edge: viewModel.transitionEdge == .trailing ? .leading : .trailing))
            ))
            
            NouriOnboardingFooter(onBack: viewModel.back, onNext: viewModel.next)
                .padding(.horizontal, 24).padding(.bottom, 32)
                .background(NouriColors.canvas)
                .zIndex(1)
        }
        .background(NouriColors.canvas.ignoresSafeArea())
        .overlay(physicsOverlay)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isShowingGoodProduct)
        .onAppear { viewModel.runStaggeredAnimation() }
        .onPreferenceChange(FramePreferenceKey.self) { frames in
            // Senior Fix: No conditions here. If bad side sends data, we take it instantly.
            if !viewModel.isShowingGoodProduct {
                viewModel.physicsSnapshots = frames
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 14) {
            Text("Product Comparison").font(.system(size: 11, weight: .bold)).foregroundStyle(.black.opacity(0.4)).padding(.horizontal, 10).padding(.vertical, 4).background(.black.opacity(0.04), in: Capsule())
            VStack(alignment: .center, spacing: 6) {
                Text("Avoiding bad ingredients is hard.").font(.system(size: 24, weight: .semibold)).tracking(-0.3).foregroundStyle(NouriColors.title).multilineTextAlignment(.center)
                Text(viewModel.activeProduct.textMessage).font(.system(size: 15, weight: .regular)).lineSpacing(4).foregroundStyle(.black.opacity(0.4)).multilineTextAlignment(.center)
                    .id("subtitle_\(viewModel.currentPairIndex)_\(viewModel.isShowingGoodProduct)")
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: viewModel.transitionEdge)), removal: .opacity.combined(with: .move(edge: viewModel.transitionEdge == .trailing ? .leading : .trailing))))
            }
        }
        .frame(maxWidth: .infinity).padding(.top, 8).padding(.bottom, 24)
    }
    
    private var productHub: some View {
        ZStack {
            ProductHubCard(product: viewModel.currentPair.bad).opacity(viewModel.is3DCardFlipped ? 0 : 1).rotation3DEffect(.degrees(viewModel.is3DCardFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            ProductHubCard(product: viewModel.currentPair.good).opacity(viewModel.is3DCardFlipped ? 1 : 0).rotation3DEffect(.degrees(viewModel.is3DCardFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .id("card_hub_\(viewModel.currentPairIndex)")
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: viewModel.transitionEdge)), removal: .opacity.combined(with: .move(edge: viewModel.transitionEdge == .trailing ? .leading : .trailing))))
        .scaleEffect(viewModel.containerTapScale)
        .onTapGesture { viewModel.toggleFlip() }
        .padding(.bottom, 32)
    }
    
    private var breakdownHeader: some View {
        HStack(alignment: .bottom) {
            Text("Ingredients Breakdown").font(.system(size: 14, weight: .bold)).tracking(0.5).foregroundStyle(Color(white: 0.63))
            Spacer()
            let filteredCount = viewModel.activeProduct.ingredients.filter { $0.bad }.count
            if filteredCount > 0 {
                Text("\(filteredCount) flagged").font(.system(size: 11, weight: .bold)).foregroundStyle(NouriColors.badProductRed).padding(.horizontal, 10).padding(.vertical, 4).background(NouriColors.badProductRed.opacity(0.1), in: Capsule()).transition(.scale.combined(with: .opacity))
            }
        }
        .id("breakdown_\(viewModel.currentPairIndex)_\(viewModel.isShowingGoodProduct)")
        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: viewModel.transitionEdge)), removal: .opacity.combined(with: .move(edge: viewModel.transitionEdge == .trailing ? .leading : .trailing))))
        .padding(.bottom, 12)
    }
    
    private var physicsOverlay: some View {
        let badIngredients = viewModel.currentPair.bad.ingredients
        let snapshots: [IngredientSnapshot] = viewModel.physicsSnapshots.compactMap { idx, frame -> IngredientSnapshot? in
            guard idx < badIngredients.count else { return nil }
            let ing = badIngredients[idx]
            return ing.bad ? IngredientSnapshot(info: ing, frame: frame) : nil
        }
        return PhysicsDropOverlay(ingredients: snapshots, trigger: viewModel.physicsTrigger).allowsHitTesting(false).ignoresSafeArea()
    }
}

// MARK: - Components

private struct IngredientListView: View {
    let product: ComparisonProduct
    let isBadSide: Bool
    @ObservedObject var viewModel: ComparisonViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 5) {
                ForEach(Array(product.ingredients.enumerated()), id: \.element.id) { index, ing in
                    let visible = index < viewModel.visibleIngredientCount
                    let hidden = isBadSide && ing.bad && viewModel.isPhysicsActive
                    IngredientBar(label: ing.label, isBad: ing.bad)
                        .opacity(hidden ? 0 : (visible ? 1 : 0))
                        .offset(y: visible ? 0 : 8)
                        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.04), value: visible)
                        .background(GeometryReader { geo in
                            if isBadSide {
                                Color.clear.preference(key: FramePreferenceKey.self, value: [index: geo.frame(in: .global)])
                            }
                        })
                }
            }
            .padding(.horizontal, 24).padding(.top, 4).padding(.bottom, 24)
        }
    }
}

private struct IngredientBar: View {
    let label: String
    let isBad: Bool
    
    var body: some View {
        HStack {
            Text(label).font(.system(size: 15, weight: .medium)).foregroundStyle(Color(white: 0.23))
            Spacer()
            Image(systemName: isBad ? "xmark" : "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(isBad ? NouriColors.badProductRed : NouriColors.brandGreen).frame(width: 22, height: 22).background((isBad ? NouriColors.badProductRed : NouriColors.brandGreen).opacity(0.1), in: Circle())
        }
        .padding(.horizontal, 12).frame(height: 38).background(isBad ? Color(red: 0.99, green: 0.95, blue: 0.95) : Color(red: 0.95, green: 0.98, blue: 0.96), in: RoundedRectangle(cornerRadius: 10, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(isBad ? Color(red: 0.96, green: 0.88, blue: 0.87) : Color(red: 0.86, green: 0.92, blue: 0.88), lineWidth: 1))
    }
}

private struct ProductHubCard: View {
    let product: ComparisonProduct
    var body: some View {
        HStack(spacing: 16) {
            Image(product.imageName).resizable().scaledToFit().frame(width: 68, height: 80).scaleEffect(product.imageScale).offset(product.imageOffset)
            VStack(alignment: .leading, spacing: 3) {
                Text(product.title).font(.system(size: 20, weight: .bold)).foregroundStyle(Color(white: 0.1))
                Text(product.subtitle).font(.system(size: 13, weight: .bold)).foregroundStyle(product.baseColor.opacity(0.85))
            }
            Spacer()
            Image(systemName: "arrow.2.circlepath").font(.system(size: 12, weight: .black)).foregroundStyle(product.baseColor).frame(width: 34, height: 34).background(product.baseColor.opacity(0.08), in: Circle())
        }
        .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1).shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 8).overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.black.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - Data Extensions

extension ComparisonProduct {
    static let lays = ComparisonProduct(title: "Lay's Chips", subtitle: "10 ingredients", imageName: "lays", textMessage: "Tap the card to see the upgrade.", baseColor: NouriColors.badProductRed, imageScale: 1.7, imageOffset: .init(width: 0, height: 2), ingredients: [("Dehydrated potatoes", false), ("Refined olive oil", false), ("Corn starch", false), ("Sugars (sugar, dextrose)", true), ("Sea salt", false), ("Soy lecithin", true), ("Mono- and diglycerides", true), ("Sodium acid pyrophosphate", true), ("Citric acid", false), ("Annatto", true)].map { IngredientInfo(label: $0.0, bad: $0.1) })
    
    static let siete = ComparisonProduct(title: "Siete Sea Salt", subtitle: "Healthy alternative", imageName: "siete", textMessage: "Siete Chips use healthy oils.", baseColor: NouriColors.brandGreen, imageScale: 1.85, imageOffset: .zero, ingredients: [("Cassava flour", false), ("Avocado oil", false), ("Coconut flour", false), ("Chia seeds", false), ("Sea salt", false)].map { IngredientInfo(label: $0.0, bad: $0.1) })
    
    static let frootLoops = ComparisonProduct(title: "Froot Loops®", subtitle: "19.4 oz", imageName: "fruit", textMessage: "Tap the card to see the upgrade.", baseColor: NouriColors.badProductRed, imageScale: 1.7, imageOffset: .init(width: 0, height: 2), ingredients: [("Corn flour", false), ("Sugar", true), ("Wheat flour", false), ("Oat flour", false), ("Modified starch", true), ("Vegetable oil", true), ("Fiber", false), ("Maltodextrin", true), ("Salt", false), ("Corn fiber", false), ("Flavors", true), ("Red 40", true), ("Yellow 5", true), ("Blue 1", true), ("Yellow 6", true), ("BHT", true)].map { IngredientInfo(label: $0, bad: $1) })
    
    static let heritage = ComparisonProduct(title: "Heritage Flakes", subtitle: "Healthy alternative", imageName: "heritage", textMessage: "Organic, clean ingredients.", baseColor: NouriColors.brandGreen, imageScale: 1.85, imageOffset: .zero, ingredients: [("Khorasan wheat", false), ("Wheat bran", false), ("Cane sugar", false), ("Barley malt", false), ("Honey", false), ("Whole wheat", false), ("Oat flour", false), ("Spelt flour", false), ("Barley flour", false), ("Millet", false), ("Quinoa", false), ("Sea salt", false)].map { IngredientInfo(label: $0, bad: $1) })
}

#Preview { CompareScreenView() }

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { old, new in new }
    }
}
