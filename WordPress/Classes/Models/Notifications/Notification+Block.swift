import Foundation



//
//
extension Notification
{
    class Block
    {
        ///
        ///
        typealias MetaKeys  = Notification.MetaKeys
        typealias BlockKeys = Notification.BlockKeys

        ///
        ///
        enum Kind {
            case Text
            case Image      // Includes Badges and Images
            case User
            case Comment
        }

        ///
        ///
        enum Action {
            case Follow
            case Like
            case Spam
            case Trash
            case Reply
            case Approve
            case Edit

            var toString: String {
                switch self {
                case Follow:    return "follow"
                case Like:      return "like-comment"
                case Spam:      return "spam-comment"
                case Trash:     return "trash-comment"
                case Reply:     return "replyto-comment"
                case Approve:   return "approve-comment"
                case Edit:      return "approve-comment"
                }
            }
        }

        ///
        ///
        private(set) var kind: Kind

        ///
        ///
        private(set) var text: String?

        ///
        ///
        var textOverride: String? {
            didSet {
                parent?.didChangeOverrides()
            }
        }

        ///
        ///
        private(set) var actions: [String: AnyObject]?

        ///
        ///
        private var actionsOverride = [Action: Bool]()

        ///
        ///
        private(set) var media: [NotificationMedia]

        ///
        ///
        private weak var parent: Notification?

        ///
        ///
        private(set) var meta: [String: AnyObject]?

        ///
        ///
        private(set) var ranges: [NotificationRange]


        ///
        ///
        private var dynamicAttributesCache = [String: AnyObject]()



        ///
        ///
        init(dictionary: [String: AnyObject], parent: Notification) {
            let rawRanges = dictionary[BlockKeys.Ranges] as? [AnyObject]
            let rawMedia = dictionary[BlockKeys.Media] as? [AnyObject]

            text        = dictionary[BlockKeys.Text] as? String
            ranges      = NotificationRange.rangesFromArray(rawRanges)
            media       = NotificationMedia.mediaFromArray(rawMedia)
            meta        = dictionary[BlockKeys.Meta] as? [String: AnyObject]
            actions     = dictionary[BlockKeys.Actions] as? [String: AnyObject]
            self.parent = parent

            kind = .Comment

            // Duck Typing code below: Infer block kind based on... stuff. (Sorry)

//            let media = media.first
//
//            //  User
//            if rawBlock[NoteTypeKey].isEqual(NoteTypeUser) {
//                kind = .User
//
//                //  Comments
//            } else if block.metaCommentID.isEqual(notification.metaCommentID) && block.metaSiteID != nil {
//                kind = .Comment
//
//                //  Images
//            } else if media?.isImage || media?.isBadge {
//                kind = .Image
//
//                //  Text
//            } else {
//                kind = .Text
//            }
        }

        /// Returns the Meta ID's collection, if any.
        ///
        private var metaIds: [String: AnyObject]? {
            return meta?[MetaKeys.Ids] as? [String: AnyObject]
        }

        /// Returns the Meta ID's collection, if any.
        ///
        private var metaLinks: [String: AnyObject]? {
            return meta?[MetaKeys.Links] as? [String: AnyObject]
        }

        ///
        ///
        private var metaTitles: [String: AnyObject]? {
            return meta?[MetaKeys.Titles] as? [String: AnyObject]
        }

        ///
        ///
        var metaSiteID: NSNumber? {
            return metaIds?[MetaKeys.Site] as? NSNumber
        }

        ///
        ///
        var metaCommentID: NSNumber? {
            return metaIds?[MetaKeys.Comment] as? NSNumber
        }

        ///
        ///
        var metaLinksHome: NSURL? {
            guard let rawLink = metaLinks?[MetaKeys.Home] as? String else {
                return nil
            }

            return NSURL(string: rawLink)
        }

        ///
        ///
        var metaTitlesHome: String? {
            return metaTitles?[MetaKeys.Home] as? String
        }

        /// Returns all of the Image URL's referenced by the NotificationMedia instances
        ///
        var imageUrls: [NSURL] {
            return media.flatMap {
                guard $0.isImage && $0.mediaURL != nil else {
                    return nil
                }

                return $0.mediaURL
            }
        }

        /// Returns YES if the associated comment (if any) is approved. NO otherwise.
        ///
        var isCommentApproved: Bool {
            return isActionOn(.Approve) || !isActionEnabled(.Approve)
        }

        /// Allows us to set a local override for a remote value. This is used to fake the UI, while
        /// there's a BG call going on.
        ///
        func setOverrideValue(value: Bool, forAction action: Action) {
            actionsOverride[action] = value
            parent?.didChangeOverrides()
        }

        /// Removes any local (temporary) value that might have been set by means of *setActionOverrideValue*.
        ///
        func removeOverrideValueForAction(action: Action) {
            actionsOverride.removeValueForKey(action)
            parent?.didChangeOverrides()
        }

        /// Returns the Notification Block status for a given action. If there's any local override,
        /// the (override) value will be returned.
        ///
        private func valueForAction(action: Action) -> Bool? {
            guard let overrideValue = actionsOverride[action] else {
                let value = actions?[action.toString] as? NSNumber
                return value?.boolValue
            }

            return overrideValue
        }

        /// Returns *true* if a given action is available
        ///
        func isActionEnabled(action: Action) -> Bool {
            return valueForAction(action) != nil
        }

        /// Returns *true* if a given action is toggled on. (I.e.: Approval = On, means that the comment
        /// is currently approved).
        ///
        func isActionOn(action: Action) -> Bool {
            return valueForAction(action) ?? false
        }

        // Dynamic Attribute Cache: used internally by the Interface Extension, as an optimization.
        ///
        func cacheValueForKey(key: String) -> AnyObject? {
            return self.dynamicAttributesCache[key]
        }

        ///
        ///
        func setCacheValue(value: AnyObject?, forKey key: String) {
            guard let value = value else {
                dynamicAttributesCache.removeValueForKey(key)
                return
            }

            dynamicAttributesCache[key] = value
        }

        /// Finds the first NotificationRange instance that maps to a given URL.
        ///
        func notificationRangeWithUrl(url: NSURL) -> NotificationRange? {
            for range in ranges {
                if let rangeURL = range.url where rangeURL.isEqual(url) {
                    return range
                }
            }

            return nil
        }

        /// Finds the first NotificationRange instance that maps to a given CommentID.
        ///
        func notificationRangeWithCommentId(commentID: NSNumber) -> NotificationRange? {
            for range in ranges {
                if let rangeCommentID = range.commentID where rangeCommentID.isEqual(commentID) {
                    return range
                }
            }

            return nil
        }

        ///
        ///
        class func fromArray(rawBlocks: [AnyObject], notification: Notification) -> [Block]? {
            let parsed: [Block] = rawBlocks.flatMap({
                guard let rawBlock = $0 as? [String: AnyObject] else {
                    return nil
                }

                return Block(dictionary: rawBlock, parent: notification)
            })

            return parsed.isEmpty ? nil : parsed
        }
    }
}
