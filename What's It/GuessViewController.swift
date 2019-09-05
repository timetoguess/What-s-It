//
//  GuessViewController.swift
//  What's It
//
//  Created by Prabhunes on 8/1/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import UIKit
import SpriteKit

class GuessViewController: UIViewController, UIViewControllerWithGradientLayer, SupportingScoreDisplay {
    
    @IBOutlet weak var magneticView: MagneticView! {
        didSet {
            magnetic.magneticDelegate = self
        }
    }
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var congratulationsMessageLabel: UILabel!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var justTellMeButton: UIButton!
    @IBOutlet weak var aiDisclaimerLabel: UILabel!

    var magnetic: Magnetic {
        return magneticView.magnetic
    }

    var gradientLayer: CAGradientLayer!
    var colorChangeAnimation: CABasicAnimation!

    var gradientTargetColors: [CGColor] = [UIColor.random.cgColor]
    var gradientTargetStartPoint: CGPoint = CGPoint.zero

    public var guessNodes: [GuessNode] = []
    public var selectedLabel = ""

    private var nodeRadius: CGFloat { return 45 }
    private var nodeColorWhenUnselected: UIColor { return UIColor(red: 0, green: 0, blue: 1, alpha: 0.3) }
    private var nodeColorWhenSelected: UIColor { return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.7) }
    private var nodeColorUponCorrectGuess: UIColor { return UIColor(red: 1, green: 0, blue: 0.2, alpha: 0.7) }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        createGradientLayer()
        answerLabel.alpha = 0
        aiDisclaimerLabel.alpha = 0

        let guessNodesShuffled = guessNodes.shuffled()
        for guessNode in guessNodesShuffled {
            addNode(guessNode)
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

    @IBAction func onTouchUpInsideJustTellMeButton(_ sender: UIButton) {

        answerLabel.text = "  \(selectedLabel.capitalized)  "

        let answerTime: TimeInterval = 5.0
        answerLabel.rotateAndScale(duration: answerTime)

        let aiDisclaimerTime = answerTime + 2.0
        aiDisclaimerLabel.fadeInAndOut(duration: aiDisclaimerTime)

        guard let thePresentingViewController = presentingViewController as? SupportingScoreUpdate else {
            print("No presentingViewController...")
            return
        }

        thePresentingViewController.updateCurrentScoreForJustTellMeOption()
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        onAnimationEnd(anim, finished: flag)
    }
}

extension GuessViewController {

    private func addNode(_ guessNode: GuessNode) {
        let node = Node(text: guessNode.name.capitalized, radius: nodeRadius, isSelected: guessNode.isSelected)
        setColorForNode(node)
        magnetic.addChild(node)
    }

    private func updateGuessNode(withNodeText nodeText: String, isNodeSelected: Bool) {

        guard let guessNode = guessNodes.first(where: { $0.name.capitalized ==  nodeText}) else {
            assert(false, "Guess node could not be located...")
            return
        }
        guessNode.isSelected = isNodeSelected
    }

    private func setColorForNode(_ node: Node) {

        if node.isSelected {
            if isGuessedNodeCorrect(node) {
                node.color = nodeColorUponCorrectGuess
            } else {
                node.color = nodeColorWhenSelected
            }
        } else {
            node.color = nodeColorWhenUnselected
        }
    }

    private func isGuessedNodeCorrect(_ node: Node) -> Bool {

        return node.text == selectedLabel.capitalized
    }
}

extension GuessViewController: MagneticDelegate {

    func magnetic(_ magnetic: Magnetic, didSelect node: Node) {

        let isNodeSelected = node.isSelected
        let nodeText = node.text ?? ""

        print("didSelect -> \(nodeText)")
        updateGuessNode(withNodeText: nodeText, isNodeSelected: isNodeSelected)
        setColorForNode(node)

        guard let thePresentingViewController = presentingViewController as? SupportingScoreUpdate else {
            print("No presentingViewController...")
            return
        }

        if isGuessedNodeCorrect(node) {
            thePresentingViewController.stopCurrentScoreUpdate()

            let action = SKAction.rotate(byAngle: CGFloat.pi, duration:2)

            node.run(SKAction.repeatForever(action))

            if congratulationsMessageLabel.isHidden {
                displayCongratulations()
            }

        } else {
            justTellMeButton.shake()
            thePresentingViewController.updateCurrentScoreForTakingAGuess()
        }
    }

    func magnetic(_ magnetic: Magnetic, didDeselect node: Node) {

        let isNodeSelected = node.isSelected
        let nodeText = node.text ?? ""

        print("didDeselect -> \(nodeText)")
        updateGuessNode(withNodeText: nodeText, isNodeSelected: isNodeSelected)
        setColorForNode(node)
    }
}

extension GuessViewController {

    func displayCongratulations() {
        congratulationsMessageLabel.isHidden = false
        UIView.transition(with: congratulationsMessageLabel, duration: 1, options: [.transitionFlipFromTop, .autoreverse, .repeat],
                           animations: {
                            self.congratulationsMessageLabel.textColor = UIColor.red
        }, completion: nil)
    }
}
