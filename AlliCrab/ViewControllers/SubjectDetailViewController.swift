//
//  SubjectDetailViewController.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

private let enFont = UIFont.preferredFont(forTextStyle: .body)
private let jpFont = UIFont(name: "Hiragino Sans W3", size: enFont.pointSize) ?? enFont

class SubjectDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let absoluteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var repositoryReader: ResourceRepositoryReader!
    var subjectID: Int?
    
    // MARK: - Outlets
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var characterView: SubjectCharacterView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var primaryMeaningLabel: UILabel!
    @IBOutlet weak var alternativeMeaningsLabel: UILabel!
    @IBOutlet weak var userSynonymsLabel: UILabel!
    @IBOutlet weak var partOfSpeechLabel: UILabel!
    
    @IBOutlet weak var radicalCombinationContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var onyomiTitleLabel: UILabel!
    @IBOutlet weak var onyomiLabel: UILabel!
    @IBOutlet weak var kunyomiTitleLabel: UILabel!
    @IBOutlet weak var kunyomiLabel: UILabel!
    @IBOutlet weak var nanoriTitleLabel: UILabel!
    @IBOutlet weak var nanoriLabel: UILabel!
    
    @IBOutlet weak var vocabularyReadingLabel: UILabel!
    
    @IBOutlet weak var contextSentencesStackView: UIStackView!
    
    @IBOutlet weak var meaningMnemonicTitleLabel: UILabel!
    @IBOutlet weak var meaningMnemonicLabel: UILabel!
    @IBOutlet weak var meaningHintView: UIView!
    @IBOutlet weak var meaningHintLabel: UILabel!
    @IBOutlet weak var meaningNoteLabel: UILabel!
    @IBOutlet weak var readingMnemonicTitleLabel: UILabel!
    @IBOutlet weak var readingMnemonicLabel: UILabel!
    @IBOutlet weak var readingHintView: UIView!
    @IBOutlet weak var readingHintLabel: UILabel!
    @IBOutlet weak var readingNoteLabel: UILabel!
    
    @IBOutlet weak var relatedSubjectsLabel: UILabel!
    @IBOutlet weak var relatedSubjectsView: UIView!
    @IBOutlet weak var relatedSubjectsContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var foundInVocabularyContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var srsStageImageView: UIImageView!
    @IBOutlet weak var srsStageNameLabel: UILabel!
    
    @IBOutlet weak var combinedAnsweredCorrectProgressBarView: ProgressBarView!
    @IBOutlet weak var meaningAnsweredCorrectProgressBarView: ProgressBarView!
    @IBOutlet weak var readingAnsweredCorrectProgressBarView: ProgressBarView!
    
    @IBOutlet weak var nextReviewTitleLabel: UILabel!
    @IBOutlet weak var nextReviewLabel: UILabel!
    @IBOutlet weak var unlockedDateLabel: UILabel!
    
    @IBOutlet var visibleViewsForRadical: [UIView]!
    @IBOutlet var visibleViewsForKanji: [UIView]!
    @IBOutlet var visibleViewsForVocabulary: [UIView]!
    @IBOutlet var reviewStatisticsViews: [UIView]!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try! updateSubjectDetail()
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container === children[0] {
            os_log("Changing height constraint for radicals", type: .debug)
            radicalCombinationContainerViewHeightConstraint.constant = container.preferredContentSize.height
        } else if container === children[1] {
            os_log("Changing height constraint for related subjects", type: .debug)
            relatedSubjectsContainerViewHeightConstraint.constant = container.preferredContentSize.height
        } else if container === children[2] {
            os_log("Changing height constraint for vocabulary", type: .debug)
            foundInVocabularyContainerViewHeightConstraint.constant = container.preferredContentSize.height
        } else {
            os_log("Content size change for unknown container %@: %@", type: .debug, ObjectIdentifier(container).debugDescription, container.preferredContentSize.debugDescription)
        }
    }
    
    // MARK: - Update UI
    
    private func updateSubjectDetail() throws {
        guard let repositoryReader = repositoryReader, let subjectID = subjectID else {
            fatalError("SubjectDetailViewController: repositoryReader or subjectID nil")
        }
        
        os_log("Fetching subject detail for %d", type: .info, subjectID)
        
        let (subject, studyMaterials, assignment, reviewStatistics) = try repositoryReader.subjectDetail(id: subjectID)
        
        characterView.subject = subject
        headerView.backgroundColor = subject.subjectType.backgroundColor
        
        levelLabel.text = String(subject.level)
        
        switch subject {
        case let r as Radical:
            navigationItem.title = r.slug
            removeSubviews(from: stackView, ifNotIn: visibleViewsForRadical)
            partOfSpeechLabel.removeFromSuperview()
            
            meaningMnemonicTitleLabel.text = "Name Mnemonic"
            setText(markup: r.meaningMnemonic, to: meaningMnemonicLabel)
            
            setRelatedSubjects(ids: r.amalgamationSubjectIDs, title: "Found In Kanji")
        case let k as Kanji:
            navigationItem.title = k.characters
            removeSubviews(from: stackView, ifNotIn: visibleViewsForKanji)
            partOfSpeechLabel.removeFromSuperview()
            
            setRadicalCombination(ids: k.componentSubjectIDs)
            
            updateKanjiReading(kanji: k, type: .onyomi, titleLabel: onyomiTitleLabel, label: onyomiLabel)
            updateKanjiReading(kanji: k, type: .kunyomi, titleLabel: kunyomiTitleLabel, label: kunyomiLabel)
            updateKanjiReading(kanji: k, type: .nanori, titleLabel: nanoriTitleLabel, label: nanoriLabel)
            
            meaningMnemonicTitleLabel.text = "Meaning Mnemonic"
            setText(markup: k.meaningMnemonic, to: meaningMnemonicLabel)
            if let meaningHint = k.meaningHint {
                setText(markup: meaningHint, to: meaningHintLabel)
            } else {
                meaningHintView.removeFromSuperview()
            }
            
            readingMnemonicTitleLabel.text = "Reading Mnemonic"
            setText(markup: k.readingMnemonic, to: readingMnemonicLabel)
            if let readingHint = k.readingHint {
                setText(markup: readingHint, to: readingHintLabel)
            } else {
                readingHintView.removeFromSuperview()
            }
            
            setRelatedSubjects(ids: k.visuallySimilarSubjectIDs, title: "Visually Similar Kanji")
            setFoundVocabulary(ids: k.amalgamationSubjectIDs)
        case let v as Vocabulary:
            navigationItem.title = v.characters
            removeSubviews(from: stackView, ifNotIn: visibleViewsForVocabulary)
            
            setText(items: v.normalisedPartsOfSpeech, title: "Part of Speech", to: partOfSpeechLabel)
            
            vocabularyReadingLabel.text = v.allReadings
            vocabularyReadingLabel.font = jpFont
            
            setContextSentences(v.contextSentences)
            
            meaningMnemonicTitleLabel.text = "Meaning Explanation"
            setText(markup: v.meaningMnemonic, to: meaningMnemonicLabel)
            readingMnemonicTitleLabel.text = "Reading Explanation"
            setText(markup: v.readingMnemonic, to: readingMnemonicLabel)
            
            setRelatedSubjects(ids: v.componentSubjectIDs, title: "Utilised Kanji")
        default:
            fatalError("Unknown subject type")
        }
        
        let primaryMeaning = subject.meanings.lazy.filter({ $0.isPrimary }).map({ $0.meaning }).first!
        primaryMeaningLabel.text = primaryMeaning
        let alternativeMeanings = subject.meanings.lazy.filter({ !$0.isPrimary }).map({ $0.meaning }).joined(separator: ", ")
        if alternativeMeanings.isEmpty {
            alternativeMeaningsLabel.removeFromSuperview()
        } else {
            alternativeMeaningsLabel.text = alternativeMeanings
        }
        
        setText(items: studyMaterials?.meaningSynonyms, title: "User Synonyms", to: userSynonymsLabel)
        
        // TODO Can only do meaning notes on items which are unlocked
        setText(note: studyMaterials?.meaningNote, to: meaningNoteLabel)
        setText(note: studyMaterials?.readingNote, to: readingNoteLabel)
        
        if let assignment = assignment,
            let srsStage = SRSStage(numericLevel: assignment.srsStage), srsStage != .initiate {
            srsStageNameLabel.text = srsStage.rawValue
            srsStageImageView.image = UIImage(named: srsStage.rawValue)!.withRenderingMode(.alwaysOriginal)
            
            if let burnedAt = assignment.burnedAt {
                nextReviewTitleLabel.text = "Retired Date"
                nextReviewLabel.text = absoluteDateFormatter.string(from: burnedAt)
            } else {
                nextReviewTitleLabel.text = "Next Review"
                switch NextReviewTime(date: assignment.availableAt) {
                case .none:
                    nextReviewLabel.text = "-"
                case .now:
                    nextReviewLabel.text = "Available Now"
                case let .date(date):
                    nextReviewLabel.text = absoluteDateFormatter.string(from: date)
                }
            }
            
            if let unlockedAt = assignment.unlockedAt {
                unlockedDateLabel.text = absoluteDateFormatter.string(from: unlockedAt)
            }
        }
        
        if let reviewStatistics = reviewStatistics, reviewStatistics.total > 0 {
            meaningAnsweredCorrectProgressBarView.progress = Float(reviewStatistics.meaningPercentageCorrect) / 100.0
            meaningAnsweredCorrectProgressBarView.totalCount = reviewStatistics.meaningTotal
            
            if subject is Radical {
                meaningAnsweredCorrectProgressBarView.title = "Name Answered Correct"
            } else {
                combinedAnsweredCorrectProgressBarView.progress = Float(reviewStatistics.percentageCorrect) / 100.0
                combinedAnsweredCorrectProgressBarView.totalCount = reviewStatistics.total
                readingAnsweredCorrectProgressBarView.progress = Float(reviewStatistics.readingPercentageCorrect) / 100.0
                readingAnsweredCorrectProgressBarView.totalCount = reviewStatistics.readingTotal
            }
        } else {
            reviewStatisticsViews.forEach { view in
                view.removeFromSuperview()
            }
        }
    }
    
    private func setRadicalCombination(ids: [Int]) {
        setSubjectIDs(ids, toChildAtIndex: 0, autoSize: true)
    }
    
    private func setRelatedSubjects(ids: [Int], title: String) {
        guard !ids.isEmpty else {
            relatedSubjectsView.removeFromSuperview()
            return
        }
        
        relatedSubjectsLabel.text = title
        setSubjectIDs(ids, toChildAtIndex: 1, autoSize: false)
    }
    
    private func setFoundVocabulary(ids: [Int]) {
        setSubjectIDs(ids, toChildAtIndex: 2, autoSize: false)
    }
    
    private func setSubjectIDs(_ ids: [Int], toChildAtIndex index: Int, autoSize: Bool) {
        let subjectSummaryViewController = children[index] as! SubjectSummaryCollectionViewController
        subjectSummaryViewController.repositoryReader = repositoryReader
        subjectSummaryViewController.subjectIDs = try! repositoryReader.filterSubjectIDsForSubscription(ids)
        
        if autoSize {
            let flowLayout = subjectSummaryViewController.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            flowLayout.estimatedItemSize = flowLayout.itemSize
        }
    }
    
    private func setContextSentences(_ sentences: [Vocabulary.ContextSentence]) {
        for sentence in sentences {
            let contextSentenceView = ContextSentenceView(frame: .zero)
            contextSentenceView.japaneseSentenceLabel.font = jpFont
            contextSentenceView.japanese = sentence.japanese
            contextSentenceView.english = sentence.english
            
            contextSentencesStackView.addArrangedSubview(contextSentenceView)
        }
    }
    
    private func updateKanjiReading(kanji: Kanji, type: ReadingType, titleLabel: UILabel, label: UILabel) {
        let textColour = kanji.isPrimary(type: type) ? .black : UIColor.darkGray.withAlphaComponent(0.75)
        titleLabel.textColor = textColour
        label.textColor = textColour
        
        if let readings = kanji.readings(type: type), readings != "None" {
            label.text = readings
            label.font = jpFont
        } else {
            label.text = "None"
            label.font = enFont
        }
    }
    
    private func setText(items: [String]?, title: String, to label: UILabel) {
        guard let items = items else {
            label.removeFromSuperview()
            return
        }
        
        let boldFont = UIFont(descriptor: label.font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: label.font.pointSize)
        let text = NSMutableAttributedString(string: title, attributes: [.font: boldFont])
        text.append(NSAttributedString(string: " " + items.joined(separator: ", ")))
        label.attributedText = text
    }
    
    private func setText(markup str: String, to label: UILabel) {
        label.attributedText = NSAttributedString(wkMarkup: str, attributes: [.font: label.font])
    }
    
    private func setText(note str: String?, to label: UILabel) {
        if let str = str {
            label.text = str
        } else {
            label.attributedText = NSAttributedString(string: "None",
                                                      attributes: [.foregroundColor: UIColor.darkGray.withAlphaComponent(0.75)])
        }
    }
    
    private func removeSubviews(from stackView: UIStackView, ifNotIn visibleViews: [UIView]) {
        stackView.arrangedSubviews.forEach { view in
            if !visibleViews.contains(view) {
                view.removeFromSuperview()
            }
        }
    }
}
