//
//  ClueViewController.swift
//  What's It
//
//  Created by Prabhunes on 7/31/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import UIKit

class ClueViewController: UIViewController, UIViewControllerWithGradientLayer, SupportingScoreDisplay {

    @IBOutlet weak var magneticView: MagneticView! {
        didSet {
            magnetic.magneticDelegate = self
        }
    }
    @IBOutlet weak var scoreLabel: UILabel!

    var magnetic: Magnetic {
        return magneticView.magnetic
    }
    var gradientLayer: CAGradientLayer!
    var colorChangeAnimation: CABasicAnimation!

    var gradientTargetColors: [CGColor] = [UIColor.random.cgColor]
    var gradientTargetStartPoint: CGPoint = CGPoint.zero

    public var clueNodes: [ClueNode] = []

    private var nodeRadius: CGFloat { return 60 }
    private var nodeColorWhenUnselected: UIColor { return UIColor(red: 0, green: 0, blue: 1, alpha: 0.3) }
    private var nodeColorWhenSelectedWithAnswerYes: UIColor { return UIColor(red: 0.2, green: 0.8, blue: 0, alpha: 0.7) }
    private var nodeColorWhenSelectedWithAnswerNo: UIColor { return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.7) }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        createGradientLayer()

        let clueNodesShuffled = clueNodes.shuffled()
        for clueNode in clueNodesShuffled {
            addNode(clueNode)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        animateGradientLayer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onTouchUpInsideDoneButton(_ sender: Any) {

        guard let thePresentingViewController = presentingViewController else {
            print("No presentingViewController...")
            return
        }

        thePresentingViewController.dismiss(animated: true, completion: nil)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        onAnimationEnd(anim, finished: flag)
    }
}

extension ClueViewController {

    private func addNode(_ clueNode: ClueNode) {

        let node = Node(text: clueNode.name.capitalized, radius: nodeRadius, isSelected: clueNode.isSelected)
        setColorForNode(node, optionalAnswer: clueNode.answer)
        magnetic.addChild(node)
    }

    private func updateClueNode(withNodeText nodeText: String, isNodeSelected: Bool) {

        guard let clueNode = clueNodes.first(where: { $0.name.capitalized ==  nodeText}) else {
            assert(false, "Clue node could not be located...")
            return
        }
        clueNode.isSelected = isNodeSelected
    }

    private func setColorForNode(_ node: Node, optionalAnswer: String? = nil) {

        var answer = ""
        if optionalAnswer != nil {

            answer = optionalAnswer!

        } else {

            let nodeText = node.text ?? ""
            guard let clueNode = clueNodes.first(where: { $0.name.capitalized ==  nodeText}) else {
                assert(false, "Guess node could not be located...")
                return
            }

            answer = clueNode.answer
        }

        var color = UIColor.clear
        if node.isSelected {
            color = answer == "Yes" ? nodeColorWhenSelectedWithAnswerYes : nodeColorWhenSelectedWithAnswerNo
        } else {
            color = nodeColorWhenUnselected
        }
        node.color = color
    }
}

extension ClueViewController: MagneticDelegate {

    func magnetic(_ magnetic: Magnetic, didSelect node: Node) {

        let isNodeSelected = node.isSelected
        let nodeText = node.text ?? ""

        print("didSelect -> \(nodeText)")
        updateClueNode(withNodeText: nodeText, isNodeSelected: isNodeSelected)
        setColorForNode(node)

        guard let thePresentingViewController = presentingViewController as? SupportingScoreUpdate else {
            print("No presentingViewController...")
            return
        }

        thePresentingViewController.updateCurrentScoreForGettingAClue()
    }

    func magnetic(_ magnetic: Magnetic, didDeselect node: Node) {

        let isNodeSelected = node.isSelected
        let nodeText = node.text ?? ""

        print("didDeselect -> \(nodeText)")
        updateClueNode(withNodeText: nodeText, isNodeSelected: isNodeSelected)
        setColorForNode(node)
    }
}
